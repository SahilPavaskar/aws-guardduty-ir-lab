import json
import os
import boto3

sns = boto3.client("sns")


def lambda_handler(event, context):
    print("Lambda invoked")
    print("Received event:")
    print(json.dumps(event, indent=2))

    detail = event.get("detail", {})

    finding_id = detail.get("id", "unknown")
    finding_type = detail.get("type", "unknown")
    severity = detail.get("severity", "unknown")
    account_id = detail.get("accountId", "unknown")
    region = detail.get("region", event.get("region", "unknown"))

    resource = detail.get("resource", {})
    instance_details = resource.get("instanceDetails", {})
    instance_id = instance_details.get("instanceId", "not-found")

    parsed_summary = {
        "finding_id": finding_id,
        "finding_type": finding_type,
        "severity": severity,
        "account_id": account_id,
        "region": region,
        "instance_id": instance_id,
    }

    print("Parsed finding summary:")
    print(json.dumps(parsed_summary, indent=2))

    sns_topic_arn = os.environ.get("SNS_TOPIC_ARN")

    if sns_topic_arn:
        subject = f"GuardDuty Alert: {finding_type}"
        message = (
            "GuardDuty finding received\n\n"
            f"Finding ID: {finding_id}\n"
            f"Type: {finding_type}\n"
            f"Severity: {severity}\n"
            f"Account ID: {account_id}\n"
            f"Region: {region}\n"
            f"Instance ID: {instance_id}\n"
        )

        response = sns.publish(
            TopicArn=sns_topic_arn,
            Subject=subject,
            Message=message
        )
        print("SNS publish response:")
        print(json.dumps(response, default=str, indent=2))
    else:
        print("SNS_TOPIC_ARN is not set")

    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": "GuardDuty finding parsed and alert sent",
            "parsed_summary": parsed_summary
        })
    }
