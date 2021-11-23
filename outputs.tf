output "lambda_bucket_name" {
    description = "Name of the S3 bucket to store the Lambda code"
    value = aws_s3_bucket.lambda_bucket.id
}

output "function_name" {
    description = "Name of the lambda function"
    value = aws_lambda_function.queue_job.function_name
}

output "base_url" {
    description = "Base URL for API Gateway Stage"
    value = aws_apigatewayv2_stage.lambda.invoke_url
}

output "queue_name" {
    description = "The name of the queue for the jobs"
    value = aws_sqs_queue.queue.name
}