# Corrigido a partir do generated.tf - conflitos do modo experimental resolvidos

resource "aws_eks_node_group" "main" {
  ami_type             = "AL2023_x86_64_STANDARD"
  capacity_type        = "ON_DEMAND"
  cluster_name         = "techchallenge-dev"
  disk_size            = 20
  force_update_version = null
  instance_types       = ["t3.small"]
  labels               = {}
  node_group_name      = "techchallenge-dev-nodes"
  node_role_arn        = "arn:aws:iam::698233916383:role/c221562a5587885l16123870t1w698233916-LabEksNodeRole-OeNFZdgwQ8GD"
  release_version      = "1.36.2-20260810"
  subnet_ids           = ["subnet-00249abf9b7073d1c", "subnet-05772bc7946cf7bec", "subnet-0d4d265fc897c606b", "subnet-0dd8c43da67ea6c67", "subnet-0fd00fe7e7d7164fd"]
  tags                 = {}
  tags_all             = {}
  version              = "1.36"
  node_repair_config {
    enabled = true
  }
  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }
  update_config {
    max_unavailable = 1
  }
}

resource "aws_eks_cluster" "main" {
  bootstrap_self_managed_addons = false
  enabled_cluster_log_types     = ["api", "audit", "authenticator"]
  force_update_version          = null
  name                          = "techchallenge-dev"
  role_arn                      = "arn:aws:iam::698233916383:role/LabRole"
  tags                          = {}
  tags_all                      = {}
  version                       = "1.36"
  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }
  compute_config {
    enabled       = true
    node_pools    = ["general-purpose", "system"]
    node_role_arn = "arn:aws:iam::698233916383:role/LabRole"
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
    security_group_ids      = ["sg-0bb5b895bc72c0ebe"]
    subnet_ids              = ["subnet-00249abf9b7073d1c", "subnet-05772bc7946cf7bec", "subnet-0d4d265fc897c606b", "subnet-0dd8c43da67ea6c67", "subnet-0fd00fe7e7d7164fd"]
  }
  zonal_shift_config {
    enabled = false
  }
}

resource "aws_vpc_security_group_ingress_rule" "nodeport_test" {
  cidr_ipv4                    = "45.191.154.144/32"
  cidr_ipv6                    = null
  description                  = "Teste NodePort TechChallenge DEV"
  from_port                    = 30643
  ip_protocol                  = "tcp"
  prefix_list_id               = null
  referenced_security_group_id = null
  security_group_id            = "sg-08937a402604c43b1"
  tags                         = null
  to_port                      = 30643
}

resource "aws_vpc_security_group_ingress_rule" "nodeport_from_alb" {
  cidr_ipv4                    = null
  cidr_ipv6                    = null
  description                  = "ALB para NodePort TechChallenge"
  from_port                    = 30643
  ip_protocol                  = "tcp"
  prefix_list_id               = null
  referenced_security_group_id = "sg-0c4b0fa0a6d1cb624"
  security_group_id            = "sg-08937a402604c43b1"
  tags                         = null
  to_port                      = 30643
}

resource "aws_security_group" "alb" {
  description = "Acesso HTTP ao ALB TechChallenge DEV 3"
  egress = [{
    cidr_blocks      = ["0.0.0.0/0"]
    description      = ""
    from_port        = 0
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "-1"
    security_groups  = []
    self             = false
    to_port          = 0
  }]
  ingress = [{
    cidr_blocks      = ["0.0.0.0/0"]
    description      = "Acesso HTTP ao ALB TechChallenge DEV"
    from_port        = 80
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "tcp"
    security_groups  = []
    self             = false
    to_port          = 80
    }, {
    cidr_blocks      = ["45.191.154.144/32"]
    description      = ""
    from_port        = 30643
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "tcp"
    security_groups  = []
    self             = false
    to_port          = 30643
    }, {
    cidr_blocks      = []
    description      = "ALB para NodePort TechChallenge"
    from_port        = 30643
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "tcp"
    security_groups  = []
    self             = true
    to_port          = 30643
  }]
  name                   = "techchallenge-dev-alb-sg"
  revoke_rules_on_delete = null
  tags                   = {}
  tags_all               = {}
  vpc_id                 = "vpc-079bb75c5a7f7678d"
}

resource "aws_lb_listener" "api" {
  alpn_policy                          = null
  certificate_arn                      = null
  load_balancer_arn                    = "arn:aws:elasticloadbalancing:us-east-1:698233916383:loadbalancer/app/techchallenge-dev-api-alb/e55296c5821d250b"
  port                                 = 80
  protocol                             = "HTTP"
  routing_http_response_server_enabled = true
  tags                                 = {}
  tags_all                             = {}
  default_action {
    order            = 1
    target_group_arn = "arn:aws:elasticloadbalancing:us-east-1:698233916383:targetgroup/techchallenge-dev-api-tg-V2/115ebfe6fc0e0732"
    type             = "forward"
    forward {
      stickiness {
        duration = 3600
        enabled  = false
      }
      target_group {
        arn    = "arn:aws:elasticloadbalancing:us-east-1:698233916383:targetgroup/techchallenge-dev-api-tg-V2/115ebfe6fc0e0732"
        weight = 1
      }
    }
  }
}

resource "aws_lb_target_group" "api" {
  deregistration_delay               = "300"
  ip_address_type                    = "ipv4"
  lambda_multi_value_headers_enabled = null
  load_balancing_algorithm_type      = "round_robin"
  load_balancing_anomaly_mitigation  = "off"
  load_balancing_cross_zone_enabled  = "use_load_balancer_configuration"
  name                               = "techchallenge-dev-api-tg-V2"
  port                                = 30643
  protocol                            = "HTTP"
  protocol_version                    = "HTTP1"
  proxy_protocol_v2                   = null
  slow_start                          = 0
  tags                                 = {}
  tags_all                             = {}
  target_type                         = "instance"
  vpc_id                               = "vpc-079bb75c5a7f7678d"
  health_check {
    enabled             = true
    healthy_threshold   = 5
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }
  stickiness {
    cookie_duration = 86400
    cookie_name     = null
    enabled         = false
    type            = "lb_cookie"
  }
}

resource "aws_lb" "api" {
  client_keep_alive                           = 3600
  customer_owned_ipv4_pool                    = null
  desync_mitigation_mode                      = "defensive"
  dns_record_client_routing_policy            = null
  drop_invalid_header_fields                  = false
  enable_cross_zone_load_balancing            = true
  enable_deletion_protection                  = false
  enable_http2                                = true
  enable_tls_version_and_cipher_suite_headers = false
  enable_waf_fail_open                        = false
  enable_xff_client_port                      = false
  enable_zonal_shift                          = false
  idle_timeout                                = 60
  internal                                    = false
  ip_address_type                             = "ipv4"
  load_balancer_type                          = "application"
  name                                        = "techchallenge-dev-api-alb"
  preserve_host_header                        = false
  security_groups                             = ["sg-0c4b0fa0a6d1cb624"]
  subnets                                     = ["subnet-070a51534012363f7", "subnet-0dd8c43da67ea6c67"]
  tags                                        = {}
  tags_all                                    = {}
  xff_header_processing_mode                  = "append"
  access_logs {
    bucket  = ""
    enabled = false
    prefix  = null
  }
  connection_logs {
    bucket  = ""
    enabled = false
    prefix  = null
  }
}
