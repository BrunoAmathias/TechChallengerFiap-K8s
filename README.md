# TechChallengerFiap-K8s

Repositório de infraestrutura do projeto TechChallengerFiap, com provisionamento de cluster Amazon EKS, recursos de rede, addons Kubernetes, políticas de IAM, controller do AWS Load Balancer Controller e integração com Terraform.

## Visão geral

Este repositório concentra a definição da infraestrutura necessária para a camada de orquestração do projeto. A base de infraestrutura está implementada em Terraform e referencia a criação de um cluster EKS na AWS, com grupos de nós, addons do Kubernetes, integration com Load Balancer Controller via Helm e configuração de variáveis sensíveis para observabilidade com New Relic.

O projeto usa a pasta `TFs` como origem principal dos artefatos de infraestrutura.

## Funcionalidades

- Provisionamento de cluster Amazon EKS com Terraform.
- Configuração de grupos de nós com instâncias `t3.small`.
- Habilitação de addons do EKS: `vpc-cni`, `kube-proxy` e `coredns`.
- Criação de política e role de IAM para o AWS Load Balancer Controller.
- Provisionamento do `ServiceAccount` do controller no namespace `kube-system`.
- Instalação do Helm release do AWS Load Balancer Controller na versão `3.5.0`.
- Configuração de integração com OIDC do cluster para IRSA.
- Suporte de configuração da chave de licença `newrelic_license_key` por variável de Terraform.

## Tecnologias

| Tecnologia | Versão / Referência | Uso |
|---|---:|---|
| Terraform | `>= 1.6.0` | Provisionamento da infraestrutura |
| AWS Provider | `~> 5.0` | Recursos AWS |
| Kubernetes Provider | `~> 2.0` | Recursos Kubernetes |
| Helm Provider | `~> 2.0` | Instalação do controller via Helm |
| TLS Provider | `~> 4.0` | Certificados OIDC |
| Amazon EKS | `1.36` | Cluster Kubernetes gerenciado |
| AWS Load Balancer Controller | `3.5.0` | Exposição e gerenciamento de Load Balancers |
| AWS IAM | [PREENCHER] | Roles, policies e trust policy |
| New Relic | [PREENCHER] | Integridade/observabilidade da infraestrutura |

## Arquitetura

A infraestrutura é definida em Terraform e organiza os recursos em camadas:

1. `provider.tf`: definição dos providers Terraform e backend S3.
2. `data.tf`: leitura de recursos já existentes na AWS, como VPC default, sub-redes e role de cluster EKS.
3. `resources.tf`: criação do cluster EKS, node group, addons, service account, IAM role/policy, OIDC e Helm release para AWS Load Balancer Controller.
4. `variables.tf`: declaração de entrada de variáveis sensíveis, como `newrelic_license_key`.
5. `terraform.tfvars`: arquivo de valores locais para execução do Terraform.

A arquitetura geral segue o fluxo:

```text
Terraform -> AWS EKS Cluster -> Kubernetes Addons -> AWS Load Balancer Controller -> Service Account -> Exposição via Load Balancer
```

## Estrutura de pastas

```text
TechChallengerFiap-K8s/
├── TFs/
│   ├── data.tf
│   ├── iam/
│   │   └── aws-load-balancer-controller-policy.json
│   ├── main.tf
│   ├── provider.tf
│   ├── resources.tf
│   ├── terraform.tfvars
│   ├── variables.tf
│   └── terraform.tfstate
├── README.md
└── [PREENCHER]
```

## Instalação

Pré-requisitos:

- Terraform `>= 1.6.0`
- AWS CLI configurado com credenciais válidas
- Conta AWS com permissões para criar EKS, IAM, VPC, subnets, load balancers e addons
- `kubectl` opcional para inspeção do cluster
- `helm` opcional para inspeção de releases

Clone o repositório:

```bash
git clone [PREENCHER]
cd TechChallengerFiap-K8s/TFs
```

Inicialize o Terraform:

```bash
terraform init
```

Valide a configuração:

```bash
terraform validate
```

Planeje a infraestrutura:

```bash
terraform plan
```

## Configuração das variáveis de ambiente

As variáveis ficam em `TFs/variables.tf` e no arquivo `TFs/terraform.tfvars`.

### Variável declarada

```hcl
variable "newrelic_license_key" {
  type      = string
  sensitive = true
}
```

### Exemplo de arquivo de variáveis

```hcl
newrelic_license_key = "[PREENCHER]"
```

Observações:

- O valor sensível deve ser mantido fora do controle de versão quando for de produção.
- Este repositório possui uma chave de licença em `terraform.tfvars` no estado local do workspace; substitua por um valor seguro conforme o ambiente de execução.

## Execução local

Este repositório não possui uma aplicação Node.js/Express executando diretamente. A execução local está concentrada na etapa de provisionamento:

```bash
cd TFs
terraform init
terraform plan
terraform apply
```

Para revisar o cluster em execução com AWS CLI e Kubernetes:

```bash
aws eks update-kubeconfig --name techchallenge-dev --region us-east-2
kubectl get nodes
kubectl get pods -A
```

## Banco de dados

Este repositório de infraestrutura não define recursos de banco de dados na pasta `TFs`. A base de dados do projeto é tratada no repositório `TechChallengerFiap-Application` e no repositório `TechChallengerFiap-DB`.

O arquivo `docker-compose.yml` localizado no backend da aplicação evidencia o uso de PostgreSQL com:

- usuário: `postgres`
- banco: `oficina`
- porta do container: `5433:5432`

Para o uso com Kubernetes, o repositório de infraestrutura não descreve, neste arquivo, a implementação do serviço de banco de dados.

## Testes

O repositório não contém uma suíte de testes explícita para a infraestrutura. A validação recomendada é a execução de:

```bash
terraform validate
terraform plan
```

Em ambientes com pipeline, a validação do Terraform deve ser incluída por etapa de CI/CD antes do `apply`.

## Exemplos de uso

### Criar o cluster EKS

```bash
cd TFs
terraform apply
```

### Validar o estado inicial

```bash
kubectl get nodes -A
kubectl get pods -A
kubectl get svc -A
```

### Verificar o release do AWS Load Balancer Controller

```bash
helm list -n kube-system
```

## Deploy

O deploy deste repositório ocorre por meio do provisionamento que cria o cluster EKS, o node group, addons e o `helm_release` do AWS Load Balancer Controller:

```bash
cd TFs
terraform apply -auto-approve
```

O fluxo de deploy considera:

- criação da IAM role para o cluster (`AmazonEKSAutoClusterRole`)
- criação do cluster EKS e configuração de VPC, subnets e endpoints
- instalação do AWS Load Balancer Controller com `serviceAccount.create = false`
- integração com `AWSLoadBalancerControllerIAMPolicy` e `AmazonEKSLoadBalancerControllerRole`

## Contribuição

Contribuições são bem-vindas por meio de branchs, commits e pull requests. Antes de abrir uma alteração, verifique a consistência do Terraform e o uso de credenciais sensíveis.

```bash
git checkout -b feature/nova-infra
terraform fmt
terraform validate
```

## Licença

