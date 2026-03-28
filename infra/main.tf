terraform {
  required_version = ">= 1.2.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.37"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_sns_topic" "incident_alerts" {
  name = "guardduty-ir-alerts"
}

resource "aws_sns_topic_subscription" "email_alerts" {
  topic_arn = aws_sns_topic.incident_alerts.arn
  protocol  = "email"
  endpoint  = "sahilpavaskar81@gmail.com"
}

output "sns_topic_arn" {
  value = aws_sns_topic.incident_alerts.arn
}

resource "aws_guardduty_detector" "main" {
  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"
}

output "guardduty_detector_id" {
  value = aws_guardduty_detector.main.id
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "guardduty-ir-lambda-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_logs" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_custom_policy" {
  name = "guardduty-ir-lambda-custom-policy"
  role = aws_iam_role.lambda_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowPublishToSns"
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.incident_alerts.arn
      },
      {
        Sid    = "AllowEc2ReadAndStop"
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:StopInstances"
        ]
        Resource = "*"
      }
    ]
  })
}

output "lambda_role_arn" {
  value = aws_iam_role.lambda_exec_role.arn
}

resource "aws_lambda_function" "guardduty_ir" {
  function_name = "guardduty-ir-handler"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.13"

  filename         = "../build/guardduty_ir_lambda.zip"
  source_code_hash = filebase64sha256("../build/guardduty_ir_lambda.zip")

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.incident_alerts.arn
    }
  }
}

output "lambda_function_name" {
  value = aws_lambda_function.guardduty_ir.function_name
}

resource "aws_cloudwatch_event_rule" "guardduty_findings" {
  name        = "guardduty-findings-to-lambda"
  description = "Send GuardDuty findings to the IR Lambda"

  event_pattern = jsonencode({
    source = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
  })
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.guardduty_findings.name
  target_id = "GuardDutyIRLambda"
  arn       = aws_lambda_function.guardduty_ir.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.guardduty_ir.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.guardduty_findings.arn
}

output "eventbridge_rule_name" {
  value = aws_cloudwatch_event_rule.guardduty_findings.name
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default_in_vpc" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_security_group" "lab_instance_sg" {
  name        = "guardduty-ir-lab-ec2-sg"
  description = "Security group for GuardDuty IR lab test instance"
  vpc_id      = data.aws_vpc.default.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "guardduty-ir-lab-ec2-sg"
    Project = "aws-guardduty-ir-lab"
  }
}

resource "aws_instance" "lab_target" {
  ami                         = data.aws_ssm_parameter.al2023_ami.value
  instance_type               = "t3.micro"
  subnet_id                   = data.aws_subnets.default_in_vpc.ids[0]
  vpc_security_group_ids      = [aws_security_group.lab_instance_sg.id]
  associate_public_ip_address = true

  tags = {
    Name        = "guardduty-ir-lab-target"
    Project     = "aws-guardduty-ir-lab"
    Environment = "lab"
    Purpose     = "incident-response-test-target"
  }
}

output "lab_instance_id" {
  value = aws_instance.lab_target.id
}
