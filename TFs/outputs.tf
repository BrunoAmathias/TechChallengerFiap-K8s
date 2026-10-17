output "ecr_repository_urls" {
  description = "URL de cada repositório ECR (use o nome como vars.ECR_REPOSITORY no repo do serviço)"
  value       = { for name, repo in aws_ecr_repository.service : name => repo.repository_url }
}

output "rabbitmq_url" {
  description = "URL AMQP do broker (já publicada como Secret 'rabbitmq' nos namespaces os, billing e execution)"
  value       = local.rabbitmq_url
  sensitive   = true
}

output "service_namespaces" {
  description = "Namespaces dos microsserviços"
  value       = [for ns in kubernetes_namespace_v1.service : ns.metadata[0].name]
}
