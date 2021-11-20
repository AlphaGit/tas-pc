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