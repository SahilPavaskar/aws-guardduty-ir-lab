# Incident Response Flow

This document explains how a GuardDuty finding moves through the AWS GuardDuty Incident Response Lab and how the response logic is applied.

## Overview

The project uses an event-driven incident response workflow. Instead of requiring manual review for every event, the pipeline automatically reacts to GuardDuty findings by routing them to a Lambda function that evaluates the event, sends an alert, and can optionally perform remediation.

The flow is intentionally simple so that each stage of the response process is easy to understand, validate, and demonstrate.

## High-Level Flow

The incident response sequence is:

1. Amazon GuardDuty detects suspicious activity and generates a finding
2. Amazon EventBridge captures the finding event
3. AWS Lambda receives and parses the finding
4. Lambda evaluates severity and resource details
5. Amazon SNS sends an alert notification
6. Lambda optionally stops the affected EC2 instance if remediation conditions are met

## Step-by-Step Response Process

### 1. Detection

The workflow begins when Amazon GuardDuty generates a finding. A finding may be produced when GuardDuty identifies suspicious or potentially malicious activity in the AWS account.

GuardDuty acts as the detection source for the entire response pipeline. Once a finding exists, it becomes the event that drives the rest of the process.

## 2. Event Routing

Amazon EventBridge listens for GuardDuty finding events. When a matching event is detected, EventBridge forwards it to the configured Lambda function.

This stage is important because it decouples detection from response. GuardDuty produces the finding, but EventBridge is responsible for routing it to the automation logic.

## 3. Event Processing

AWS Lambda receives the GuardDuty event and begins processing it.

At this stage, the function extracts the key fields needed for the response, such as:

- finding type
- severity
- title or description
- affected resource details
- account or region metadata

This turns the raw event into actionable information for downstream logic.

## 4. Severity Evaluation

After parsing the event, Lambda evaluates the GuardDuty severity against the configured remediation threshold.

This is a key decision point in the workflow.

The function determines:
- whether the event should only generate an alert
- whether it should generate an alert and trigger remediation
- whether the event references a resource that can be acted on

This keeps the response logic controlled and predictable.

## 5. Alerting

Once the event has been evaluated, Lambda publishes a message to an Amazon SNS topic.

The SNS notification is used to communicate:
- that a finding was received
- What type of finding was processed
- the severity of the finding
- whether remediation was attempted or skipped

This provides visibility into the workflow and serves as evidence that the automation pipeline executed.

## 6. Remediation Decision

Before taking any containment action, Lambda checks whether remediation is enabled through configuration.

Even if a finding is severe, remediation should only occur when:
- automated remediation is enabled
- the severity threshold is met or exceeded
- The finding contains a target resource that the function can safely act on

This design prevents the function from taking action unconditionally.

## 7. Containment Action

If remediation conditions are satisfied, Lambda calls the EC2 API to stop the affected instance.

In this lab, stopping the EC2 instance is the containment action. It is a simple and visible remediation step that demonstrates how an automated response can reduce the time between detection and action.

## 8. Logging and Traceability

Throughout the workflow, Lambda writes execution details to Amazon CloudWatch Logs.

These logs help confirm:
- that the function was invoked
- What finding was processed
- What severity decision was made
- whether SNS publishing succeeded
- whether remediation was attempted

This makes the incident flow easier to troubleshoot and validate.

## Response Modes

The workflow can operate in two modes, depending on configuration.

### Alert-Only Mode

In alert-only mode:
- Lambda processes the finding
- SNS sends an email notification
- No EC2 stop action is taken

This mode is useful when testing or when automated containment is not desired.

### Alert-and-Remediate Mode

In alert-and-remediate mode:
- Lambda processes the finding
- SNS sends an email notification
- EC2 remediation is performed if severity conditions are met

This mode demonstrates automated containment behavior.

## Configuration Controls

The flow is controlled by Lambda environment variables:

- `SNS_TOPIC_ARN` specifies the SNS topic used for notifications
- `REMEDIATE_INSTANCES` enables or disables EC2 remediation
- `SEVERITY_THRESHOLD` defines the minimum severity required before remediation

These controls make the response logic adjustable without code changes.

## Example Incident Path

A typical incident path in this lab looks like this:

1. GuardDuty generates a finding for suspicious activity
2. EventBridge matches the event and sends it to Lambda
3. Lambda extracts the finding details
4. Lambda compares the severity to the configured threshold
5. Lambda publishes an SNS alert
6. Lambda stops the EC2 instance if remediation is enabled and conditions are met
7. CloudWatch logs record the full execution path

This demonstrates the full lifecycle from detection to containment.

## Why This Flow Matters

This flow is useful because it mirrors the structure of real security automation pipelines:

- A detection source generates a signal
- an event-routing service forwards the signal
- A response engine evaluates the event
- a notification service alerts responders
- an automated action contains the threat when appropriate

Even though this lab is intentionally simplified, it reflects core principles used in production cloud security operations.

## Limitations

This incident flow is intentionally narrow in scope. It does not include:

- triage workflows for analysts
- ticket creation or case management
- approval-based remediation
- automated evidence collection
- branching remediation paths for multiple AWS resource types

These are valid next steps for future versions of the project.

## Summary

The AWS GuardDuty Incident Response Lab demonstrates a straightforward but realistic incident response flow. A GuardDuty finding is routed by EventBridge, processed by Lambda, alerted through SNS, and used to trigger optional EC2 containment. This creates a clear example of event-driven security automation in AWS.
