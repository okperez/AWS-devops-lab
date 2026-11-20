resource "aws_ecr_repository" "image_repo" {
  name         = "image-repo"
  force_delete = true
}

resource "aws_ecr_lifecycle_policy" "image_repo_policy" {
  repository = aws_ecr_repository.image_repo.name

  policy = jsonencode({
    "rules" = [
      {
        rulePriority = 1
        description  = "Keep only the latest app build"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["app-"]
          countType     = "imageCountMoreThan"
          countNumber   = 1
        }
        action = {
          type = "expire"
        }
      },
      {
        "rulePriority" = 2,
        "description"  = "Expire images older than 14 days",
        "selection" = {
          "tagStatus"   = "untagged",
          "countType"   = "sinceImagePushed",
          "countUnit"   = "days",
          "countNumber" = 14
        },
        "action" = {
          "type" = "expire"
        }
      }
    ]
    }
  )
}