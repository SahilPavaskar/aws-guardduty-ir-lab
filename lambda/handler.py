import json
import os


def lambda_handler(event, context):
    print("Lambda invoked")
    print("Received event:")
    print(json.dumps(event, indent=2))

    response = {
        "message": "GuardDuty IR Lambda skeleton executed successfully",
        "sns_topic_arn": os.environ.get("SNS_TOPIC_ARN", "not-set")
    }

    return {
        "statusCode": 200,
        "body": json.dumps(response)
    }
