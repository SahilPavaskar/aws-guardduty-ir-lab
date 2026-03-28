# Architecture Notes

This document provides additional detail about the architecture used in the AWS GuardDuty Incident Response Lab.

## Overview

The lab is built as a lightweight event-driven security response workflow in AWS. Its purpose is to demonstrate how GuardDuty findings can be automatically routed, processed, alerted on, and optionally remediated using managed AWS services.

The overall design focuses on simplicity, visibility, and modularity. Each AWS service has a clearly defined responsibility in the pipeline.

## Architecture Diagram

![Architecture Diagram](./images/architecture-diagram.png)

## Core Workflow

The architecture follows this sequence:

1. Amazon GuardDuty generates a finding after detecting suspicious or potentially malicious activity.
2. Amazon EventBridge matches the GuardDuty finding event and routes it to an AWS Lambda function.
3. AWS Lambda parses the finding, extracts key metadata, evaluates severity, and decides whether remediation should occur.
4. Amazon SNS sends an email notification containing the finding details and the response outcome.
5. If automated remediation is enabled and the severity threshold is met, the Lambda function stops the affected EC2 instance.

## Design Goals

This architecture was designed with the following goals in mind:

- Demonstrate event-driven security automation in AWS
- Use managed services to minimize operational overhead
- Keep remediation logic configurable without changing code
- Provide clear alerting and logging for validation
- Show a realistic but beginner-friendly incident response workflow

## Service Responsibilities

### Amazon GuardDuty

GuardDuty is the detection source in this project. It continuously monitors supported AWS data sources and produces security findings when suspicious behavior is identified.

In this lab, GuardDuty acts as the trigger point for the response workflow. Without GuardDuty findings, the downstream event-driven pipeline would not activate.

### Amazon EventBridge

EventBridge is used as the routing layer between detection and response. It listens for GuardDuty findings and forwards matching events to the Lambda function.

This service makes the workflow event-driven and decoupled. GuardDuty does not need direct knowledge of Lambda, and Lambda only runs when a relevant event is received.

### AWS Lambda

Lambda acts as the response engine. It receives the GuardDuty event, parses the payload, evaluates the finding severity, and determines whether remediation conditions are met.

The Lambda function is also responsible for:
- formatting alert content
- publishing notifications to SNS
- checking whether remediation is enabled
- stopping the EC2 instance when required

This makes Lambda the core decision point in the architecture.

### Amazon SNS

SNS provides the alerting mechanism for the lab. Once the Lambda function processes a finding, it publishes a message to an SNS topic, which then delivers the notification to a subscribed email address.

This allows the workflow to produce visible evidence that the event was processed successfully.

### Amazon EC2

EC2 represents the workload that may be affected by a GuardDuty finding. In this lab, EC2 is the resource that can be acted on during remediation.

If the finding severity is high enough and automated remediation is enabled, the Lambda function can stop the target instance as a containment action.

### AWS IAM

IAM is used to provide the Lambda function with the permissions required to perform its tasks securely.

The Lambda execution role includes permissions for:
- writing logs to CloudWatch
- publishing to SNS
- describing EC2 instances
- stopping EC2 instances

This is an important part of the design because automated response workflows depend on correct permission scoping.

## Remediation Model

The remediation model in this project is intentionally simple. Rather than attempting complex orchestration, the workflow applies a single containment action: stopping an EC2 instance.

Whether this action occurs depends on configurable conditions:
- remediation must be enabled
- the GuardDuty severity must meet or exceed the configured threshold
- the finding must reference a resource that the function can act on

This keeps the workflow easy to understand and test while still demonstrating real security automation concepts.

## Configuration Approach

The Lambda function uses environment variables to control behavior:

- `SNS_TOPIC_ARN` defines where alerts are sent
- `REMEDIATE_INSTANCES` determines whether automated remediation is enabled
- `SEVERITY_THRESHOLD` defines the minimum severity required before remediation is triggered

This approach makes the system more flexible because operational behavior can be changed without modifying the code.

## Logging and Observability

CloudWatch Logs are used to record Lambda execution details. These logs provide visibility into:
- whether the function was triggered
- what finding was received
- what decision the function made
- whether SNS publishing succeeded
- whether remediation was attempted

This is useful both for troubleshooting and for proving that the workflow executed as intended during testing.

## Why This Architecture Is Effective for a Lab

This design works well for a portfolio project because it demonstrates several important cloud security concepts in a focused way:

- managed threat detection
- event-driven architecture
- serverless processing
- automated alerting
- configurable remediation
- least-privilege IAM design

It is also small enough to understand end to end, which makes it a strong learning project and a clear portfolio artifact.

## Limitations

This architecture is intentionally simplified for learning purposes. It does not include:
- multi-account aggregation
- forensic evidence collection
- ticketing system integration
- enrichment from external threat intelligence
- support for multiple remediation strategies

These limitations are acceptable for a lab and provide a natural path for future improvements.

## Future Enhancements

Possible architectural improvements include:
- adding Slack or Teams alerting
- storing findings in DynamoDB or S3
- adding automated tagging for affected resources
- supporting remediation for additional AWS resource types
- introducing different response paths based on finding type
- extending the design to multi-account AWS environments
