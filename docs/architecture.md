# Architecture - AWS GuardDuty IR Lab

## Project Goal
Build an automated incident response workflow in AWS that reacts to GuardDuty findings.

## Version 1 Scope
Version 1 of this project will:

- enable GuardDuty
- use EventBridge to listen for GuardDuty findings
- trigger a Lambda function automatically
- send an SNS email alert
- log the finding details in CloudWatch
- prepare for EC2 remediation

## Main AWS Services

### GuardDuty
Detects suspicious activity and generates security findings.

### EventBridge
Receives GuardDuty findings and routes them to Lambda.

### Lambda
Processes the finding and decides what action to take.

### SNS
Sends an email notification about the incident.

### CloudWatch
Stores logs from the Lambda function.

### EC2
Represents the compute instance that may later be stopped or quarantined.

## Basic Flow

1. A GuardDuty finding is created
2. EventBridge receives the event
3. EventBridge triggers Lambda
4. Lambda parses the finding
5. Lambda logs the details
6. Lambda sends an SNS alert
7. In a later step, Lambda will stop or isolate the EC2 instance

## Version 1 Success Criteria

Version 1 is successful when:

- GuardDuty is enabled
- EventBridge triggers Lambda from a GuardDuty finding
- Lambda runs successfully
- SNS sends an email alert
- CloudWatch logs show the event details

## Future Improvements

Future versions may include:

- stopping EC2 instances automatically
- quarantining EC2 instances with a security group
- tagging affected resources
- severity-based response logic
- better alert formatting
- Security Hub integration

## Notes
This project is inspired by an existing cloud incident response lab, but is being rebuilt with a new structure and implementation.
