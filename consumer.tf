resource "aws_lambda_function" "exec_job" {
    function_name = var.consumer_lambda_name

    s3_bucket = aws_s3_bucket.lambda_bucket.id
    s3_key = aws_s3_bucket_object.lambda_exec_job.key

    runtime = var.consumer_lambda_runtime
    handler = var.consumer_lambda_handler

    source_code_hash = data.archive_file.lambda_exec_job.output_base64sha256

    role = aws_iam_role.lambda_exec.arn
}

resource "aws_s3_bucket_object" "lambda_exec_job" {
    bucket = aws_s3_bucket.lambda_bucket.id

    key = "consumer_lambda.zip"
    source = data.archive_file.lambda_exec_job.output_path

    etag = filemd5(data.archive_file.lambda_exec_job.output_path)
}

data "archive_file" "lambda_exec_job" {
    type = "zip"

    source_dir = var.consumer_lambda_source_path
    output_path = "${path.module}/tmp/consumer_lambda.zip"
}

resource "aws_lambda_event_source_mapping" "event_source_mapping" {
    event_source_arn = aws_sqs_queue.queue.arn
    enabled = true
    function_name = aws_lambda_function.exec_job.arn
    batch_size = 1
}