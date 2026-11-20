data "aws_caller_identity" "current" {}

locals {
  app_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ecr-role"

  app_instance_profile_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:instance-profile/ecr_instance_profile"

  app_ecr_policy_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/ecr-pull-policy"
}

resource "aws_iam_openid_connect_provider" "GitHub_OIDC" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]
}

resource "aws_iam_role" "GitHub_OIDC_role" {
  name               = "GitHub_OIDC_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.GitHub_OIDC.arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:okperez@113048960/AWS-devops-lab@1456422924:ref:refs/heads/main"]
    }
  }
}

data "aws_iam_policy_document" "GitHub_OIDC_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.state_storage.arn
    ]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["terraform/*"]
    }
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
    ]
    resources = [
      "${aws_s3_bucket.state_storage.arn}/terraform/terraform.tfstate"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      "${aws_s3_bucket.state_storage.arn}/terraform/terraform.tfstate.tflock"
    ]
  }
}

resource "aws_iam_policy" "GitHub_OIDC_policy" {
  name   = "GitHub_OIDC_policy"
  policy = data.aws_iam_policy_document.GitHub_OIDC_policy.json
}

resource "aws_iam_role_policy_attachment" "GitHub_OIDC_policy_attachment" {
  role       = aws_iam_role.GitHub_OIDC_role.name
  policy_arn = aws_iam_policy.GitHub_OIDC_policy.arn
}


# Allow GitHub Actions to pass the application role to EC2.
data "aws_iam_policy_document" "GitHub_OIDC_policy_pass_role" {
  statement {
    effect = "Allow"
    actions = [
      "iam:PassRole"
    ]
    resources = [
      local.app_role_arn
    ]
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ec2.amazonaws.com"]
    }
  }
}

# Attach the custom PassRole policy to the GitHub role, not to the application role.
resource "aws_iam_role_policy_attachment" "GitHub_OIDC_pass_role_attachment" {
  role       = aws_iam_role.GitHub_OIDC_role.name
  policy_arn = aws_iam_policy.GitHub_OIDC_policy_pass_role.arn
}

resource "aws_iam_policy" "GitHub_OIDC_policy_pass_role" {
  name   = "GitHub_OIDC_policy_pass_role"
  policy = data.aws_iam_policy_document.GitHub_OIDC_policy_pass_role.json
}

# Attach the separate AWS-managed PowerUserAccess policy.
resource "aws_iam_role_policy_attachment" "GitHub_OIDC_policy_poweruser" {
  role       = aws_iam_role.GitHub_OIDC_role.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

data "aws_iam_policy_document" "GitHub_OIDC_policy_actions_list" {
  statement {
    effect = "Allow"
    actions = [
      "iam:createrole",
      "iam:attachrolepolicy",
      "iam:detachrolepolicy",
      "iam:deleterole",
      "iam:updateassumerolepolicy",
      "iam:getrole",
      "iam:listattachedrolepolicies",
      "iam:listinstanceprofilesforrole",
      "iam:ListRolePolicies",
      "iam:TagRole",
      "iam:UntagRole"
    ]
    resources = [
      local.app_role_arn
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "iam:createinstanceprofile",
      "iam:deleteinstanceprofile",
      "iam:getinstanceprofile",
      "iam:addroletoinstanceprofile",
      "iam:removerolefrominstanceprofile",
      "iam:TagInstanceProfile",
      "iam:UntagInstanceProfile"
    ]
    resources = [
    local.app_instance_profile_arn]
  }
  statement {
    effect = "Allow"
    actions = [
      "iam:createpolicy",
      "iam:deletepolicy",
      "iam:getpolicy",
      "iam:getpolicyversion",
      "iam:listpolicyversions",
      "iam:createpolicyversion",
      "iam:deletepolicyversion",
      "iam:setdefaultpolicyversion",
      "iam:tagpolicy",
      "iam:untagpolicy"
    ]
    resources = [
      local.app_ecr_policy_arn
    ]
  }
}

resource "aws_iam_policy" "GitHub_OIDC_policy_actions_list" {
  name   = "GitHub_OIDC_policy_actions_list"
  policy = data.aws_iam_policy_document.GitHub_OIDC_policy_actions_list.json
}
resource "aws_iam_role_policy_attachment" "GitHub_OIDC_policy_actions_list_attachment" {
  role       = aws_iam_role.GitHub_OIDC_role.name
  policy_arn = aws_iam_policy.GitHub_OIDC_policy_actions_list.arn
}