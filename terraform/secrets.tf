# Essas três propriedades existem para que a troca futura por credencial
# **gerenciada pelo proprio RDS** — `manage_master_user_password = true`, cujo
# segredo tem nome gerado e não escolhido — seja gratuita: basta apontar o mesmo 
# output para `aws_db_instance.rds_postgres.master_user_secret[0].secret_arn`.
# A credencial gerenciada produz exatamente `username` e `password`, mais campos
# de motor, endereco, porta e nome do banco, que o leitor ignora.

resource "aws_secretsmanager_secret" "db_credentials" {
  name        = local.db_credentials_secret_name
  description = "Credencial do banco PostgreSQL, na forma usuario e senha"

  recovery_window_in_days = 0

  tags = {
    Name = local.db_credentials_secret_name
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id

  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
  })
}
