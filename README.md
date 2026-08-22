<div align="center">

# 🐘 Oficina Mecânica — Banco de Dados Relacional AWS RDS (IaC)

**Provisionamento automatizado do banco de dados relacional Amazon RDS PostgreSQL na AWS com Terraform para a solução Oficina Mecânica.**

![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.11.0-844FBA?logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-Cloud-FF9900?logo=amazon-aws&logoColor=white)
![Amazon RDS](https://img.shields.io/badge/AWS-RDS_PostgreSQL-527FFF?logo=amazon-rds&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16.9-4169E1?logo=postgresql&logoColor=white)

</div>

## 📋 Sobre

Este repositório contém o código de **Infraestrutura como Código (IaC)** responsável pelo provisionamento do banco de dados relacional gerenciado **Amazon RDS (PostgreSQL)** para a aplicação **Oficina Mecânica**.

Faz parte do ecossistema de microsserviços e infraestrutura da pós-graduação em Arquitetura de Software da FIAP (turma 15SOAT, Fase 2).

### 🏗️ Recursos Provisionados

1. **Amazon RDS PostgreSQL (`rds.tf`)**:
   - Instância gerenciada do PostgreSQL na versão **16.9** (Single-AZ para otimização de custos de laboratório).
   - Tipo de instância: `db.t4g.micro` (ou `db.t3.micro`).
   - Armazenamento: `20 GiB` GP3 com criptografia em repouso ativada (`storage_encrypted = true`).
   - Acesso estritamente privado (`publicly_accessible = false`), alocado nas subnets privadas da VPC.
   - `skip_final_snapshot = true` para permitir destruição limpa e automatizada em ambientes de teste/laboratório.

2. **DB Subnet Group (`rds.tf`)**:
   - Agrupamento de subnets (`dbsng-oficina-mecanica`) utilizando as subnets privadas em múltiplas Zonas de Disponibilidade consumidas de `oficina-mecanica-infra-base`.

3. **Security Group do RDS (`security_group.tf`)**:
   - Regras de firewall (`secgrp-rds-oficina-mecanica`) liberando tráfego TCP na porta `5432` exclusivamente para o bloco CIDR da VPC (`10.0.0.0/16`) onde os pods do EKS operam.

---

## 📁 Estrutura do Repositório

```text
.
├── .github/
│   └── workflows/
│       ├── ci.yml        # Validação do Terraform (fmt, validate, plan) e abertura automática de PR
│       └── cd.yml        # Deploy automatizado (terraform apply) em push na main ou disparo manual
├── terraform/
│   ├── backend.tf        # Configuração do backend S3 com lock nativo
│   ├── providers.tf      # Provider AWS e data source de Remote State
│   ├── locals.tf         # Convenções de nomenclatura e tags locais
│   ├── variables.tf      # Declaração de variáveis de entrada
│   ├── security_group.tf # Security Group dedicado do PostgreSQL RDS
│   ├── rds.tf            # Instância RDS e DB Subnet Group
│   ├── outputs.tf        # Saídas (endpoint, address, port, db_name, security_group_id)
│   ├── terraform.tfvars  # Valores padrão do laboratório
│   └── terraform.tfvars.example
└── .gitignore
```

---

## 💾 Estado Remoto (Remote State)

O estado do Terraform é armazenado remotamente no Amazon S3 com criptografia e lock nativo do S3 (`use_lockfile = true`):

- **Bucket**: `bkt-oficina-mecanica`
- **Chave (Key)**: `infra/prod-simulated/database/terraform.tfstate`
- **Região**: `us-east-1`

### 🔗 Integração com `oficina-mecanica-infra-base`

Este repositório consome as subnets privadas e o CIDR da VPC provisionados pelo repositório [`oficina-mecanica-infra-base`](https://github.com/FIAP-15SOAT/oficina-mecanica-infra-base) diretamente via **Remote State**:

```hcl
data "terraform_remote_state" "aws_base" {
  backend = "s3"
  config = {
    bucket = var.aws_base_state_bucket
    key    = var.aws_base_state_key
    region = var.aws_base_state_region
  }
}
```

---

## 🔐 Configuração de Secrets e Variáveis no GitHub Actions

Para a execução automatizada dos pipelines de CI e CD, configure os seguintes parâmetros nas configurações do repositório:

### Secrets do GitHub (`Settings > Secrets and variables > Actions > Secrets`)

| Secret | Descrição |
|---|---|
| `AWS_ACCESS_KEY_ID` | Access Key do AWS Academy / Learner Lab |
| `AWS_SECRET_ACCESS_KEY` | Secret Access Key do AWS Academy |
| `AWS_SESSION_TOKEN` | Token temporário de sessão do AWS Academy |
| `OPEN_PR_TOKEN` | Personal Access Token (PAT) com escopo `repo` para abertura automática de PRs no CI |
| `TF_VAR_db_password` *(ou `DB_PASSWORD`)* | Senha mestra do banco PostgreSQL (ex: `OficinaDb#2026!Prod`) |

### Variáveis do GitHub (`Settings > Secrets and variables > Actions > Variables`)

| Variável | Valor Padrão | Descrição |
|---|---|---|
| `ENABLE_DEPLOY` | `true` | Habilita a execução do job `terraform apply` no workflow de CD |

---

## 🚀 Como Executar Localmente

### Pré-requisitos
- [Terraform](https://developer.hashicorp.com/terraform/install) $\ge$ 1.11.0
- [AWS CLI](https://aws.amazon.com/cli/) instalado e configurado com credenciais válidas

### Passos para Inicialização e Deploy

```bash
# 1. Acesse o diretório do Terraform
cd terraform

# 2. Defina a senha do banco em uma variável de ambiente
export TF_VAR_db_password="SuaSenhaSeguraAqui123!"

# 3. Inicialize o backend e os provedores
terraform init

# 4. Formate e valide a sintaxe
terraform fmt -check
terraform validate

# 5. Planeje as alterações
terraform plan

# 6. Aplique a infraestrutura
terraform apply
```

---

## 📤 Saídas Principais (Outputs)

Após o provisionamento, o Terraform exporta as seguintes informações:

| Output | Descrição | Exemplo |
|---|---|---|
| `db_endpoint` | Host e porta para conexão | `rds-oficina-mecanica.xxxx.us-east-1.rds.amazonaws.com:5432` |
| `db_address` | Endereço DNS do host | `rds-oficina-mecanica.xxxx.us-east-1.rds.amazonaws.com` |
| `db_port` | Porta do PostgreSQL | `5432` |
| `db_name` | Nome inicial do banco | `techchallenge` |
| `db_security_group_id` | ID do Security Group do RDS | `sg-0123456789abcdef0` |