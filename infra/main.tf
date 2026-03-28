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
