data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Role que a AWS criou automaticamente quando o EKS Auto Mode foi habilitado
data "aws_iam_role" "eks_auto" {
  name = "AmazonEKSAutoClusterRole"
}
