
resource "aws_iam_user" "sa" {
  name = "${local.project-name}-SA"
  tags = merge(local.tags, {
    Name                 = "${local.project-name}-SA"
    yb_aws_service       = "iam"
    yb_aws_resource_type = "user"
  })
}

resource "aws_iam_access_key" "sa-access-key" {
  user = aws_iam_user.sa.name
}


resource "aws_iam_policy" "yba-policy" {
  name   = "${local.project-name}-YBA-Policy"

  description = "${local.project-name} YBA Policy"

  policy = <<YBA_JSON
{
  "Statement": [
      {
          "Action": [
              "route53:ChangeResourceRecordSets"
          ],
          "Effect": "Allow",
          "Resource": "*",
          "Sid": "HostedZoneEditor"
      },
      {
          "Action": [
              "route53:Get*",
              "route53:List*"
          ],
          "Effect": "Allow",
          "Resource": "*",
          "Sid": "HostedZoneReader"
      },
      {
          "Action": [
              "iam:GetRole",
              "iam:PassRole"
          ],
          "Effect": "Allow",
          "Resource": "*",
          "Sid": "IamReader"
      },
      {
          "Action": [
              "kms:CreateKey",
              "kms:ListAliases",
              "kms:ListKeys",
              "kms:CreateAlias",
              "kms:DeleteAlias",
              "kms:UpdateAlias",
              "kms:TagResource"
          ],
          "Effect": "Allow",
          "Resource": "*",
          "Sid": "KMSManagement"
      },
      {
          "Action": [
              "kms:Decrypt",
              "kms:GenerateDataKey"
          ],
          "Effect": "Allow",
          "Resource": "*",
          "Sid": "KMSDecryptor"
      },
      {
          "Action": [
              "ec2:*"
          ],
          "Effect": "Allow",
          "Resource": "*",
          "Sid": "EC2Manager"
      }
  ],
  "Version": "2012-10-17"
}
YBA_JSON
  tags = merge(local.tags, {
    Name                 = "${local.project-name}-YBA-Policy"
    yb_aws_service       = "iam"
    yb_aws_resource_type = "policy"
  })
}

resource "aws_iam_user_policy_attachment" "yba-policy-attach" {
  user       = aws_iam_user.sa.name
  policy_arn = aws_iam_policy.yba-policy.arn
}
