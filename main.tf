terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 3.48.0"
        }
        archive = {
            source = "hashicorp/archive"
            version = "~> 2.2.0"
        }
    }

    required_version = "~> 1.0"
}

provider "aws" {
    region = var.aws_region

    default_tags {
        tags = {
          "project" = "blender-lambda"
        }
    }
}

resource "aws_s3_bucket" "lambda_bucket" {
    bucket = var.lambda_bucket
    acl = "private"
    force_destroy = true
}

data "archive_file" "lambda_queue_render_job" {
    type = "zip"

    source_dir = "${path.module}/queue_render_job"
    output_path = "${path.module}/tmp/queue_render_job.zip"
}

resource "aws_s3_bucket_object" "lambda_queue_render_job" {
    bucket = aws_s3_bucket.lambda_bucket.id

    key = "queue_render_job.zip"
    source = data.archive_file.lambda_queue_render_job.output_path

    etag = filemd5(data.archive_file.lambda_queue_render_job.output_path)
}

resource "aws_lambda_function" "queue_render_job" {
    function_name = "queue_render_job"

    s3_bucket = aws_s3_bucket.lambda_bucket.id
    s3_key = aws_s3_bucket_object.lambda_queue_render_job.key

    runtime = "python3.8"
    handler = "queue_render_job.lambda_handler"

    source_code_hash = data.archive_file.lambda_queue_render_job.output_base64sha256

    role = aws_iam_role.lambda_exec.arn

    environment {
        variables = {
            "QUEUE_NAME" = aws_sqs_queue.render_queue.name
        }
    }
}

resource "aws_cloudwatch_log_group" "queue_render_job" {
    name = "/aws/lambda/${aws_lambda_function.queue_render_job.function_name}"

    retention_in_days = 30
}

resource "aws_iam_role" "lambda_exec" {
    name = "blender_lambda_role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17",
        Statement = [{
            Action = "sts:AssumeRole",
            Effect = "Allow",
            Sid = "",
            Principal = {
                Service = "lambda.amazonaws.com"
            }
        }]
    })
}

data "aws_iam_policy_document" "render_lambda_policy_document" {
    statement {
        sid = "RenderLambdaPolicy"
        actions = [
            "sqs:ReceiveMessage",
            "sqs:DeleteMessage",
            "sqs:GetQueueAttributes",
            "sqs:SendMessage",
            "sqs:GetQueueUrl"
        ]
        resources = [
            aws_sqs_queue.render_queue.arn
        ]
    }
}

resource "aws_iam_policy" "render_lambda_policy" {
    name = "render_lambda_policy"
    policy = data.aws_iam_policy_document.render_lambda_policy_document.json
}

resource "aws_iam_role_policy_attachment" "lambda_sqs_policy" {
    role = aws_iam_role.lambda_exec.name
    policy_arn = aws_iam_policy.render_lambda_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_basic_policy" {
    role = aws_iam_role.lambda_exec.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_apigatewayv2_api" "lambda" {
    name = "blender_lambda_gw"
    protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "lambda" {
    api_id = aws_apigatewayv2_api.lambda.id

    name = "blender_lambda_stage"
    auto_deploy = true

    access_log_settings {
        destination_arn = aws_cloudwatch_log_group.api_gw.arn

        format = jsonencode({
            requestId = "$context.requestId",
            sourceIp = "$context.identity.sourceIp",
            requestTime = "$context.requestTime",
            protocol = "$context.protocol",
            httpMethod = "$context.httpMethod",
            resourcePath = "$context.resourcePath",
            routeKey = "$context.routeKey",
            status = "$context.status",
            responseLength = "$context.responseLength",
            integrationErrorMessage = "$context.integrationErrorMessage",
        })
    }
}

resource "aws_apigatewayv2_integration" "queue_render" {
    api_id = aws_apigatewayv2_api.lambda.id

    integration_uri = aws_lambda_function.queue_render_job.invoke_arn
    integration_type = "AWS_PROXY"
    integration_method = "POST"
}

resource "aws_apigatewayv2_route" "queue_render" {
    api_id = aws_apigatewayv2_api.lambda.id

    route_key = "POST /queue_render"
    target = "integrations/${aws_apigatewayv2_integration.queue_render.id}"
}

resource "aws_cloudwatch_log_group" "api_gw" {
    name = "/aws/api_gw/${aws_apigatewayv2_api.lambda.name}"
    
    retention_in_days = 30
}

resource "aws_lambda_permission" "api_gw" {
    statement_id = "AllowExecutionFromAPIGateway"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.queue_render_job.function_name
    principal = "apigateway.amazonaws.com"

    source_arn = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
}

resource "aws_sqs_queue" "render_queue" {
    name = "blender_lambda_queue"

    visibility_timeout_seconds = 300
}

resource "aws_lambda_function" "exec_render_job" {
    function_name = "exec_render_job"

    s3_bucket = aws_s3_bucket.lambda_bucket.id
    s3_key = aws_s3_bucket_object.lambda_exec_render_job.key

    runtime = "python3.8"
    handler = "exec_render_job.lambda_handler"

    source_code_hash = data.archive_file.lambda_exec_render_job.output_base64sha256

    role = aws_iam_role.lambda_exec.arn
}

resource "aws_s3_bucket_object" "lambda_exec_render_job" {
    bucket = aws_s3_bucket.lambda_bucket.id

    key = "exec_render_job.zip"
    source = data.archive_file.lambda_exec_render_job.output_path

    etag = filemd5(data.archive_file.lambda_exec_render_job.output_path)
}

data "archive_file" "lambda_exec_render_job" {
    type = "zip"

    source_dir = "${path.module}/exec_render_job"
    output_path = "${path.module}/tmp/exec_render_job.zip"
}

resource "aws_lambda_event_source_mapping" "event_source_mapping" {
    event_source_arn = aws_sqs_queue.render_queue.arn
    enabled = true
    function_name = aws_lambda_function.exec_render_job.arn
    batch_size = 1
}