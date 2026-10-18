# ---------------------------------------------------------------------------
# Namespaces: um por microsserviço + messaging (RabbitMQ).
# ---------------------------------------------------------------------------

locals {
  service_namespaces = toset(["os", "billing", "execution"])
}

resource "kubernetes_namespace_v1" "service" {
  for_each = local.service_namespaces

  metadata {
    name = each.value

    labels = {
      "app.kubernetes.io/part-of" = "oficina"
    }
  }

  depends_on = [aws_eks_node_group.main]
}

resource "kubernetes_namespace_v1" "messaging" {
  metadata {
    name = "messaging"

    labels = {
      "app.kubernetes.io/part-of" = "oficina"
    }
  }

  depends_on = [aws_eks_node_group.main]
}

# ---------------------------------------------------------------------------
# StorageClass do EKS Auto Mode (block_storage habilitado no cluster).
# ---------------------------------------------------------------------------

resource "kubernetes_storage_class_v1" "auto_ebs" {
  metadata {
    name = "auto-ebs-gp3"
  }

  storage_provisioner    = "ebs.csi.eks.amazonaws.com"
  volume_binding_mode    = "WaitForFirstConsumer"
  reclaim_policy         = "Delete"
  allow_volume_expansion = true

  parameters = {
    type      = "gp3"
    encrypted = "true"
  }
}

# ---------------------------------------------------------------------------
# RabbitMQ (chart local em charts/rabbitmq, imagem oficial).
# ---------------------------------------------------------------------------

resource "random_password" "rabbitmq" {
  length  = 32
  special = false
}

resource "helm_release" "rabbitmq" {
  name      = "rabbitmq"
  namespace = kubernetes_namespace_v1.messaging.metadata[0].name
  chart     = "${path.module}/charts/rabbitmq"

  wait    = true
  timeout = 600

  set_sensitive {
    name  = "auth.password"
    value = random_password.rabbitmq.result
  }

  set {
    name  = "persistence.enabled"
    value = tostring(var.rabbitmq_persistence)
  }

  set {
    name  = "persistence.storageClass"
    value = kubernetes_storage_class_v1.auto_ebs.metadata[0].name
  }

  # Volumes do Auto Mode só montam em nós Auto Mode.
  dynamic "set" {
    for_each = var.rabbitmq_persistence ? [1] : []

    content {
      name  = "nodeSelector.eks\\.amazonaws\\.com/compute-type"
      value = "auto"
    }
  }

  depends_on = [
    aws_eks_addon.coredns,
    aws_eks_addon.kube_proxy
  ]
}

locals {
  rabbitmq_url = "amqp://oficina:${random_password.rabbitmq.result}@rabbitmq.${kubernetes_namespace_v1.messaging.metadata[0].name}.svc.cluster.local:5672"
}

# Token compartilhado das chamadas service-to-service (rotas /internal).
resource "random_password" "service_token" {
  length  = 48
  special = false
}

resource "kubernetes_secret_v1" "service_auth" {
  for_each = kubernetes_namespace_v1.service

  metadata {
    name      = "service-auth"
    namespace = each.value.metadata[0].name
  }

  data = {
    SERVICE_TOKEN = random_password.service_token.result
  }
}

# Cada serviço recebe a URL do broker no próprio namespace (Secret "rabbitmq").
resource "kubernetes_secret_v1" "rabbitmq_url" {
  for_each = kubernetes_namespace_v1.service

  metadata {
    name      = "rabbitmq"
    namespace = each.value.metadata[0].name
  }

  data = {
    RABBITMQ_URL = local.rabbitmq_url
  }
}
