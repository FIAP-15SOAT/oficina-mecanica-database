# ADR 0002: Credencial do banco via variável Terraform sensível, sem AWS Secrets Manager

## Status

Aceito — 2026-09-07

## Contexto

A instância RDS (ADR 0001) precisa de uma senha mestra do PostgreSQL. Essa senha precisa existir em algum lugar do fluxo de provisionamento — declarada como código, gerenciada por um serviço de segredos, ou gerada automaticamente pela AWS — e cada opção tem implicações diferentes de rotação, auditoria e complexidade operacional.

## Decisão

Declarar a senha como uma **variável Terraform marcada `sensitive = true`** (`variable "db_password"`, `terraform/variables.tf`), sem valor `default`, injetada em tempo de execução via `TF_VAR_db_password` — que, nos pipelines de CI/CD, vem do GitHub Secret `TF_VAR_db_password`/`DB_PASSWORD` (ver `README.md` › Secrets do GitHub Actions). Não há AWS Secrets Manager, nem `random_password` gerado pelo próprio Terraform, nem rotação automática — a senha é definida manualmente e permanece estática até ser trocada manualmente.

## Alternativas consideradas

### AWS Secrets Manager com rotação automática

Eliminaria a senha de qualquer variável de pipeline, com rotação automática periódica e integração nativa do RDS para trocar a senha sem downtime. Descartado nesta entrega porque adiciona um recurso AWS (Secrets Manager) e sua própria política de acesso IAM — que a conta AWS Academy não permite criar livremente (só roles pré-existentes, ver ADR 0001 do `oficina-mecanica-infra-base`) — para um ganho de segurança que, num laboratório de curta duração recriado com frequência, tem retorno menor do que numa conta de produção de longa duração.

### `random_password` gerado pelo próprio Terraform

Eliminaria a necessidade de qualquer humano definir ou digitar a senha, gerando um valor aleatório armazenado apenas no state. Descartado porque o valor gerado ficaria em texto plano dentro do arquivo de state no S3 (o backend já é criptografado, mas o valor ainda precisaria ser lido de algum output para uso em `DATABASE_URL` pela aplicação) — manter a senha como uma variável de pipeline explícita, nunca persistida em state gerado, mantém o segredo inteiramente fora do controle do Terraform.

### Senha em `terraform.tfvars` versionado

Seria a opção mais simples operacionalmente — sem necessidade de configurar secrets no GitHub. Descartada de imediato: versionar uma senha de banco de dados em texto plano no repositório é uma prática insegura básica, incompatível com qualquer padrão mínimo de segurança, independentemente do contexto de laboratório.

## Consequências

### Positivas

- **Segredo nunca versionado no repositório**: a variável não tem `default`, então a única forma de fornecer o valor é via `TF_VAR_db_password` em tempo de execução — impossível de esquecer commitado em `terraform.tfvars`.
- **`sensitive = true` reduz exposição acidental**: o Terraform mascara o valor em `plan`/`apply`/logs de CI, evitando que a senha apareça em texto plano na saída de um pipeline.
- **Simplicidade operacional**: não exige provisionar nem gerenciar um recurso AWS adicional (Secrets Manager) nem sua política de acesso.

### Negativas / Trade-offs

- **Sem rotação automática**: a senha permanece a mesma até ser trocada manualmente (atualizando o GitHub Secret e reaplicando) — um processo manual e sujeito a ser esquecido, inadequado para um ambiente de produção real de longa duração.
- **Ainda existe em texto plano no state do Terraform** (`aws_db_instance.rds_postgres.password`), mesmo que mascarada na saída de `plan`/`apply` — qualquer pessoa com acesso de leitura ao bucket S3 do state pode extrair a senha atual do arquivo de state.
- **Dependência de disciplina operacional humana**: a segurança do segredo depende inteiramente de quem tem acesso ao GitHub Secret nunca vazá-lo, sem nenhum controle automático adicional (rotação, auditoria de acesso) reforçando isso.

### Riscos aceitos

- **Senha estática sem rotação**: aceito para o contexto de laboratório de curta duração; uma conta de produção real exigiria Secrets Manager com rotação automática antes de aceitar este mesmo design.
- **Senha legível no state do Terraform**: aceito porque o bucket S3 do state já tem controle de acesso próprio (fora do escopo desta ADR) e o valor é mascarado nas saídas de CI, reduzindo (não eliminando) a superfície de exposição.

## Referências

- [ADR 0001 — Banco de dados relacional como serviço gerenciado (Amazon RDS)](0001-banco-gerenciado-amazon-rds.md)
- `terraform/variables.tf` (declaração de `db_password`), `README.md` › Secrets do GitHub Actions.
