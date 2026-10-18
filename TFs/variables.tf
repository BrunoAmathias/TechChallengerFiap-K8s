variable "newrelic_license_key" {
  type      = string
  sensitive = true
}

variable "node_instance_types" {
  description = <<-EOT
    Tipos de instância do node group. A conta AWS está no Free Plan, que só
    permite tipos elegíveis ao Free Tier (t3.medium é recusado). c7i-flex.large
    (2 vCPU, 4 GiB, até 29 pods) comporta 3 serviços + RabbitMQ + New Relic;
    t3.small (2 GiB, 11 pods) não.
  EOT
  type        = list(string)
  default     = ["c7i-flex.large"]
}

variable "rabbitmq_persistence" {
  description = <<-EOT
    Usa PVC (EBS gp3 do Auto Mode) para os dados do RabbitMQ. Exige um nó Auto
    Mode, cujo tipo de instância o Free Plan pode recusar, por isso o padrão é
    false (emptyDir nos nós do node group). Sem PVC as mensagens em fila se
    perdem se o pod reiniciar; o outbox de cada serviço republica o que ainda
    não foi confirmado pelo broker.
  EOT
  type        = bool
  default     = false
}

variable "ecr_images_to_keep" {
  description = "Quantidade de imagens mantidas em cada repositório ECR"
  type        = number
  default     = 15
}
