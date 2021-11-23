variable "aws_region" {
    description = "AWS region for all resources"

    type = string
    default = "us-east-1"
}

variable "lambda_bucket" {
    description = "Bucket for all lambda archives"

    type = string
    default = "temp-lambda-archive-bucket"
}

variable "default_tags" {
    type = map
    description = "Default tags to apply to all resources"
    default = {}
}

variable "producer_lambda_source_path" {
    description = "Path to the producer lambda source"

    type = string
    default = "./queue_job"
}

variable "producer_lambda_runtime" {
    description = "Runtime for the producer lambda"

    type = string
    default = "python3.8"
}

variable "producer_lambda_handler" {
    description = "Handler for the producer lambda"

    type = string
    default = "queue_job.lambda_handler"
}

variable "producer_apigateway_stage_name" {
    description = "Name of the API gateway stage for the producer lambda"

    type = string
    default = "prod"
}

variable "producer_invocation_route_key" {
    description = "Route key for the producer lambda"

    type = string
    default = "POST /queue"
}

variable "consumer_lambda_name" {
    description = "Name of the consumer lambda"

    type = string
    default = "consumer"
}

variable "consumer_lambda_runtime" {
    description = "Runtime for the consumer lambda"

    type = string
    default = "python3.8"
}

variable "consumer_lambda_handler" {
    description = "Handler for the consumer lambda"

    type = string
    default = "exec_job.lambda_handler"
}

variable "consumer_lambda_source_path" {
    description = "Path to the consumer lambda source"

    type = string
    default = "./exec_job"
}