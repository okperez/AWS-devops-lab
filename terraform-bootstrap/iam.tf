resource "aws_iam_openid_connect_provider" "GitHub_OIDC" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.GitHub_OIDC.arn]
    }

    actions = ["AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:OWNER@OWNER_ID/REPO@REPO_ID:ref:refs/heads/BRANCH"]
    }
  }
}

# data "aws_iam_policy_document" "ecr_pull" {
#   statement {
#     sid       = "AuthenticateToECR"
#     effect    = "Allow"
#     actions   = ["ecr:GetAuthorizationToken"]
#     resources = ["*"]
#   }

#   statement {
#     sid    = "PullFromApplicationRepository"
#     effect = "Allow"
#     actions = [
#       "ecr:BatchCheckLayerAvailability",
#       "ecr:BatchGetImage",
#       "ecr:GetDownloadUrlForLayer",
#     ]
#     resources = [aws_ecr_repository.image_repo.arn]
#   }
# }
