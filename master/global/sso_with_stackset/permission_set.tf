data "aws_iam_policy_document" "secops" {
  statement {
    effect = "Allow"

    actions = [
      "cloudtrail:CreateTrail",
      "cloudtrail:DeleteTrail",
      "cloudtrail:DescribeTrails",
      "cloudtrail:StartLogging",
      "cloudtrail:StopLogging",
      "cloudtrail:UpdateTrail",
      "cloudwatch:PutMetricAlarm",
      "cloudwatch:DeleteAlarms",
      "cloudwatch:DescribeAlarms",
      "config:PutConfigurationRecorder",
      "config:DeleteConfigurationRecorder",
      "config:DescribeConfigurationRecorders",
      "config:PutConfigRule",
      "config:DeleteConfigRule",
      "config:DescribeConfigRules",
      "guardduty:CreateDetector",
      "guardduty:DeleteDetector",
      "guardduty:DescribeDetectors",
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:ListRoles",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "organizations:DescribeOrganization",
      "organizations:ListAccounts",
      "organizations:ListOrganizationalUnitsForParent",
      "organizations:DescribeOrganizationalUnit",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:PutBucketPolicy",
      "s3:GetBucketPolicy",
      "s3:DeleteBucketPolicy",
      "s3:ListBucket",
      "s3:GetObject",
    ]

    resources = ["*"]
  }
}

data "aws_iam_policy_document" "devops" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:DescribeInstances",
      "s3:ListBucket",
      "s3:GetObject",
      "dynamodb:Scan",
      "dynamodb:Query",
      "lambda:InvokeFunction",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "ec2:StartInstances",
      "ec2:StopInstances",
      "ec2:RebootInstances",
      "s3:PutObject",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "lambda:UpdateFunctionCode",
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = ["us-east-2", "ap-northeast-2"]
    }
  }

  statement {
    effect = "Deny"

    actions = [
      "iam:*",
      "organizations:*",
    ]

    resources = ["*"]
  }
}
