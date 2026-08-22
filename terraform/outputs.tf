output "db_instance_id" {
  description = "RDS instance ID"
  value       = aws_db_instance.rds_postgres.id
}

output "db_instance_arn" {
  description = "RDS instance ARN"
  value       = aws_db_instance.rds_postgres.arn
}

output "db_endpoint" {
  description = "RDS connection endpoint"
  value       = aws_db_instance.rds_postgres.endpoint
}

output "db_address" {
  description = "RDS hostname address"
  value       = aws_db_instance.rds_postgres.address
}

output "db_port" {
  description = "RDS port"
  value       = aws_db_instance.rds_postgres.port
}

output "db_name" {
  description = "Database name"
  value       = aws_db_instance.rds_postgres.db_name
}

output "db_security_group_id" {
  description = "Security group ID of the RDS instance"
  value       = aws_security_group.secgrp_rds.id
}
