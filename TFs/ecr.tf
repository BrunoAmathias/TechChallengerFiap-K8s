# Repositórios de imagem dos microsserviços. O CD de cada serviço publica
# com a tag do commit (SHA) e "latest".

locals {
  ecr_repositories = toset(["os-service", "billing-service", "execution-service"])
}

resource "aws_ecr_repository" "service" {
  for_each = local.ecr_repositories

  name                 = each.value
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

# Mantém só as últimas imagens para não acumular custo de armazenamento.
resource "aws_ecr_lifecycle_policy" "service" {
  for_each = aws_ecr_repository.service

  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Mantem as ultimas ${var.ecr_images_to_keep} imagens"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.ecr_images_to_keep
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
