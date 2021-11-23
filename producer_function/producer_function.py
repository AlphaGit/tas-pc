import boto3
import json
import os

QUEUE_NAME = os.environ['QUEUE_NAME']

def lambda_handler(event, context):
    print('Received event: ' + json.dumps(event, indent=2))

    sqs = boto3.resource('sqs')
    queue = sqs.get_queue_by_name(QueueName=QUEUE_NAME)
    body = queue.send_message(MessageBody=json.dumps(event))
    return {
        'statusCode': 200,
        'body': json.dumps(body)
    }
