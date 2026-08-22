import {
  to = aws_eks_cluster.main
  id = "techchallenge-dev"
}

import {
  to = aws_eks_node_group.main
  id = "techchallenge-dev:techchallenge-dev-nodes"
}

import {
  to = aws_lb.api
  id = "arn:aws:elasticloadbalancing:us-east-1:698233916383:loadbalancer/app/techchallenge-dev-api-alb/e55296c5821d250b"
}

import {
  to = aws_lb_target_group.api
  id = "arn:aws:elasticloadbalancing:us-east-1:698233916383:targetgroup/techchallenge-dev-api-tg-V2/115ebfe6fc0e0732"
}

import {
  to = aws_lb_listener.api
  id = "arn:aws:elasticloadbalancing:us-east-1:698233916383:listener/app/techchallenge-dev-api-alb/e55296c5821d250b/e33fab625c0f23a2"
}

import {
  to = aws_security_group.alb
  id = "sg-0c4b0fa0a6d1cb624"
}

import {
  to = aws_vpc_security_group_ingress_rule.nodeport_from_alb
  id = "sgr-0caa1302d9a960018"
}

# Opcional - só mantenha se essa regra do seu IP ainda fizer sentido existir.
# Se era só um teste pontual, remova este bloco.
import {
  to = aws_vpc_security_group_ingress_rule.nodeport_test
  id = "sgr-02ab0878ad44dea52"
}
