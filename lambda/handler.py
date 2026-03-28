import json
import os
import boto3

sns = boto3.client("sns")
ec2 = boto3.client("ec2")


def lambda_handler(event, context):
    print("Lambda invoked")
    print("Received event:")
    print(json.dumps(event, indent=2))

    detail = event.get("detail", {})

    finding_id = detail.get("id", "unknown")
    finding_type = detail.get("type", "unknown")
    severity = detail.get("severity", 0)
    account_id = detail.get("accountId", "unknown")
    region = detail.get("region", event.get("region", "unknown"))

    resource = detail.get("resource", {})
    instance_details = resource.get("instanceDetails", {})
    instance_id = instance_details.get("instanceId")

    try:
        severity_value = float(severity)
    except Exception:
        severity_value = 0.0

    severity_threshold = float(os.environ.get("SEVERITY_THRESHOLD", "4"))
    remediate_instances = os.environ.get("REMEDIATE_INSTANCES", "false").lower() == "true"
    sns_topic_arn = os.environ.get("SNS_TOPIC_ARN")

    parsed_summary = {
        "finding_id": finding_id,
        "finding_type": finding_type,
        "severity": severity_value,
        "account_id": account_id,
        "region": region,
        "instance_id": instance_id,
        "severity_threshold": severity_threshold,
        "remediate_instances": remediate_instances
    }

    print("Parsed finding summary:")
    print(json.dumps(parsed_summary, indent=2))

    remediation_result = "No remediation performed"

    if remediate_instances and instance_id and severity_value >= severity_threshold:
        print(f"Stopping EC2 instance: {instance_id}")

        stop_response = ec2.stop_instances(InstanceIds=[instance_id])
        print("EC2 stop response:")
        print(json.dumps(stop_response, default=str, indent=2))

        remediation_result = f"StopInstances called for {instance_id}"
    else:
        print("Remediation conditions not met")

    if sns_topic_arn:
        subject = f"GuardDuty Alert: {finding_type}"
        message = (
            "GuardDuty finding received\n\n"
            f"Finding ID: {finding_id}\n"
            f"Type: {finding_type}\n"
            f"Severity: {severity_value}\n"
            f"Account ID: {account_id}\n"
            f"Region: {region}\n"
            f"Instance ID: {instance_id}\n"
            f"Remediation Result: {remediation_result}\n"
        )

        sns_response = sns.publish(
            TopicArn=sns_topic_arn,
            Subject=subject,
            Message=message
        )
        print("SNS publish response:")
        print(json.dumps(sns_response, default=str, indent=2))
    else:
        print("SNS_TOPIC_ARN is not set")

    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": "GuardDuty finding processed",
            "parsed_summary": parsed_summary,
            "remediation_result": remediation_result
        })
    }
