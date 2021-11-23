resource "aws_s3_bucket" "lambda_bucket" {
    bucket = var.lambda_bucket
    acl = "private"
    force_destroy = true
}

resource "aws_iam_role" "lambda_exec" {
    name = "lambda_role"

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

data "aws_iam_policy_document" "lambda_policy_document" {
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
            aws_sqs_queue.queue.arn
        ]
    }
}

resource "aws_iam_policy" "lambda_policy" {
    name = "lambda_policy"
    policy = data.aws_iam_policy_document.lambda_policy_document.json
}

resource "aws_iam_role_policy_attachment" "lambda_sqs_policy" {
    role = aws_iam_role.lambda_exec.name
    policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_basic_policy" {
    role = aws_iam_role.lambda_exec.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_permission" "api_gw" {
    statement_id = "AllowExecutionFromAPIGateway"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.queue_job.function_name
    principal = "apigateway.amazonaws.com"

    source_arn = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
}

resource "aws_sqs_queue" "queue" {
    name = var.queue_name

    visibility_timeout_seconds = 300
}