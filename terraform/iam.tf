resource "aws_iam_role" "ecr_role" {
  name = "ecr-role"

  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = {
    tag-key = "tag-value"
  }
}

resource "aws_iam_instance_profile" "ecr_instance_profile" {
  name = "ecr_instance_profile"
  role = aws_iam_role.ecr_role.name
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "ecr_pull" {
  statement {
    sid       = "AuthenticateToECR"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid    = "PullFromApplicationRepository"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]
    resources = [aws_ecr_repository.image_repo.arn]
  }
}

resource "aws_iam_policy" "ecr_pull" {
  name   = "ecr-pull-policy"
  policy = data.aws_iam_policy_document.ecr_pull.json
}

resource "aws_iam_role_policy_attachment" "ecr_pull" {
  role       = aws_iam_role.ecr_role.name
  policy_arn = aws_iam_policy.ecr_pull.arn
}