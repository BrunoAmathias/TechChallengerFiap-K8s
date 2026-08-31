resource "aws_eks_cluster" "main" {
  name                          = "techchallenge-dev"
  role_arn                      = data.aws_iam_role.eks_auto.arn
  version                       = "1.36"
  bootstrap_self_managed_addons = false

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator"
  ]

  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }

  compute_config {
    enabled       = true
    node_pools    = ["general-purpose", "system"]
    node_role_arn = data.aws_iam_role.eks_auto.arn
  }

  kubernetes_network_config {
    ip_family         = "ipv4"
    service_ipv4_cidr = "10.100.0.0/16"

    elastic_load_balancing {
      enabled = true
    }
  }

  storage_config {
    block_storage {
      enabled = true
    }
  }

  upgrade_policy {
    support_type = "STANDARD"
  }

  vpc_config {
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
    subnet_ids              = data.aws_subnets.default.ids
  }

  zonal_shift_config {
    enabled = false
  }

  # Mantém a tag criada pelo eksctl quando o OIDC foi associado.
  tags = {
    "alpha.eksctl.io/cluster-oidc-enabled" = "true"
  }
}

# Obtém o certificado utilizado pelo endpoint OIDC do cluster.
data "tls_certificate" "eks_oidc" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

# Provider OIDC necessário para IRSA.
resource "aws_iam_openid_connect_provider" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    data.tls_certificate.eks_oidc.certificates[0].sha1_fingerprint
  ]

  # Mantém as tags adicionadas pelo eksctl.
  tags = {
    "alpha.eksctl.io/cluster-name"   = "techchallenge-dev"
    "alpha.eksctl.io/eksctl-version" = "0.230.0"
  }
}

# VPC CNI precisa estar disponível antes do Managed Node Group.
resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "vpc-cni"
}

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "techchallenge-dev-node"

  node_role_arn = "arn:aws:iam::080152070993:role/AmazonEKSNodeRole"

  subnet_ids = data.aws_subnets.default.ids

  instance_types = ["t3.small"]
  capacity_type  = "ON_DEMAND"
  disk_size      = 20

  scaling_config {
    desired_size = 1
    min_size     = 1
    max_size     = 2
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_eks_addon.vpc_cni
  ]
}

# Kube Proxy é criado depois que o Node Group estiver disponível.
resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "kube-proxy"

  depends_on = [
    aws_eks_node_group.main
  ]
}

# CoreDNS precisa de nodes disponíveis para agendar seus Pods.
resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "coredns"

  depends_on = [
    aws_eks_node_group.main
  ]
}

# Policy oficial do AWS Load Balancer Controller.
#
# A propriedade description foi intencionalmente omitida.
# A Policy criada manualmente não possui description e adicioná-la
# forçaria a substituição do recurso.
resource "aws_iam_policy" "lb_controller" {
  name = "AWSLoadBalancerControllerIAMPolicy"

  policy = file(
    "${path.module}/iam/aws-load-balancer-controller-policy.json"
  )
}

# Role assumida pelo Service Account do AWS Load Balancer Controller.
resource "aws_iam_role" "lb_controller" {
  name = "AmazonEKSLoadBalancerControllerRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        }

        Action = "sts:AssumeRoleWithWebIdentity"

        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  # Mantém as tags criadas pelo eksctl.
  tags = {
    "alpha.eksctl.io/cluster-name"                = "techchallenge-dev"
    "alpha.eksctl.io/eksctl-version"              = "0.230.0"
    "alpha.eksctl.io/iamserviceaccount-name"      = "kube-system/aws-load-balancer-controller"
    "eksctl.cluster.k8s.io/v1alpha1/cluster-name" = "techchallenge-dev"
  }
}

# Associa a Policy à Role do Controller.
resource "aws_iam_role_policy_attachment" "lb_controller" {
  role       = aws_iam_role.lb_controller.name
  policy_arn = aws_iam_policy.lb_controller.arn
}

# Service Account utilizado pelo AWS Load Balancer Controller.
resource "kubernetes_service_account" "lb_controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"

    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.lb_controller.arn
    }

    labels = {
      "app.kubernetes.io/managed-by" = "eksctl"
    }
  }

  depends_on = [
    aws_eks_node_group.main,
    aws_iam_role_policy_attachment.lb_controller
  ]
}

# Instala e gerencia o AWS Load Balancer Controller via Helm.
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  namespace  = "kube-system"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"

  # Mesma versão atualmente instalada manualmente.
  version = "3.5.0"

  # Mantém os mesmos valores do release atualmente instalado.
  atomic          = false
  cleanup_on_fail = false
  wait            = true
  timeout         = 300

  set {
    name  = "clusterName"
    value = aws_eks_cluster.main.name
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.lb_controller.metadata[0].name
  }

  # Necessário porque a descoberta automática via Instance Metadata falhou.
  set {
    name  = "region"
    value = "us-east-2"
  }

  # Necessário porque a descoberta automática da VPC falhou anteriormente.
  set {
    name  = "vpcId"
    value = data.aws_vpc.default.id
  }

  depends_on = [
    kubernetes_service_account.lb_controller,
    aws_eks_addon.vpc_cni,
    aws_eks_addon.kube_proxy,
    aws_eks_addon.coredns
  ]
}