# AWS GuardDuty Incident Response Lab

A hands-on AWS cloud security project that demonstrates how to detect suspicious activity with Amazon GuardDuty and respond automatically using an event-driven workflow built with Amazon EventBridge, AWS Lambda, Amazon SNS, and Amazon EC2.

This lab simulates a basic incident response pipeline in which GuardDuty findings trigger a Lambda function that sends alerts and can optionally stop an affected EC2 instance when the finding severity meets a defined threshold.

---

## Project Overview

In real cloud environments, security teams cannot manually monitor every event or finding. They rely on automated detection and response workflows to reduce response time and contain threats quickly.

This project shows how AWS managed services can be combined to create a lightweight incident response pipeline:

- **Amazon GuardDuty** detects suspicious activity and generates findings
- **Amazon EventBridge** routes those findings to a response function
- **AWS Lambda** evaluates the event and decides whether remediation is needed
- **Amazon SNS** sends an alert with finding and response details
- **Amazon EC2** represents the workload that may be remediated
- **AWS IAM** controls permissions for the automation workflow

The project is intended as a practical lab for learning cloud detection engineering, serverless automation, and basic incident response design in AWS.

---

## Objectives

This lab was built to demonstrate:

- Threat detection using Amazon GuardDuty
- Event-driven automation with Amazon EventBridge
- Serverless incident response using AWS Lambda
- Alerting through Amazon SNS
- Automated EC2 remediation based on finding severity
- Secure IAM role design with least-privilege permissions

---

## Architecture Diagram

The following diagram shows how Amazon GuardDuty findings flow through the incident response pipeline. When GuardDuty generates a finding, Amazon EventBridge matches the event and invokes an AWS Lambda function. The Lambda function analyzes the finding, publishes an alert through Amazon SNS, and can optionally stop the affected EC2 instance when the finding severity meets the configured remediation threshold.

![Architecture Diagram](./docs/images/architecture-diagram.png)

---

## How It Works

This lab follows a simple event-driven workflow:

1. **Amazon GuardDuty** generates a security finding based on suspicious activity in the AWS account.
2. **Amazon EventBridge** listens for GuardDuty findings and forwards matching events to AWS Lambda.
3. **AWS Lambda** parses the event, extracts the finding details, and evaluates whether remediation conditions are met.
4. **Amazon SNS** sends an email notification containing the finding details and remediation result.
5. **Amazon EC2** may be stopped automatically if remediation is enabled and the finding severity is above the configured threshold.

---

## Infrastructure Components

### Amazon GuardDuty
Used as the managed threat detection service that generates findings based on suspicious activity observed in the AWS account.

### Amazon EventBridge
Used to capture GuardDuty findings in near real time and route them to the Lambda response function.

### AWS Lambda
Acts as the incident response engine. It processes the finding, determines whether automated remediation should occur, and publishes an alert.

### Amazon SNS
Used to send email notifications with details about the detected finding and any action taken.

### Amazon EC2
Represents the workload that may be investigated or automatically stopped depending on the response logic.

### AWS IAM
Provides the Lambda execution role with the least-privilege permissions required for:
- Writing logs to CloudWatch
- Publishing notifications to SNS
- Describing EC2 instances
- Stopping EC2 instances when remediation is enabled

---

## Features

- Managed threat detection with Amazon GuardDuty
- Event-driven finding routing with Amazon EventBridge
- Serverless response handling with AWS Lambda
- Email alerting with Amazon SNS
- Optional automated EC2 remediation
- Severity-based response logic
- Configurable Lambda behavior through environment variables
- CloudWatch logging for visibility and troubleshooting

---

## Remediation Logic

The Lambda function uses environment variables to keep behavior configurable without changing the code:

- `SNS_TOPIC_ARN` - SNS topic ARN used for alert delivery
- `REMEDIATE_INSTANCES` - Enables or disables automated EC2 stopping
- `SEVERITY_THRESHOLD` - Minimum GuardDuty severity required before remediation occurs

This makes the workflow flexible and easy to test. The same function can be used in both alert-only and alert-plus-remediation modes.

---

## Security Workflow Summary

The project follows this containment flow:

- GuardDuty detects suspicious activity
- A finding is generated
- EventBridge forwards the event to Lambda
- Lambda evaluates severity and target resource information
- SNS sends an alert to the configured email recipient
- If remediation is enabled and the threshold is met, Lambda stops the affected EC2 instance

---

## Repository Structure

```text
aws-guardduty-ir-lab/
├── README.md
├── .gitignore
├── docs/
│   ├── architecture.md
│   └── images/
│       ├── architecture-diagram.png
│       ├── ec2-stopped.png
│       ├── eventbridge-rule.png
│       ├── guardduty-enabled.png
│       ├── lambda-logs.png
│       ├── lambda-overview.png
│       └── sns-email-alert.png
├── infra/
│   ├── main.tf
│   └── .terraform.lock.hcl
└── lambda/
    └── handler.py
