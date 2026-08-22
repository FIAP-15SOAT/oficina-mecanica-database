resource "aws_security_group" "secgrp_rds" {
  name        = local.secgrp_rds_name
  description = "Security group for RDS PostgreSQL instance"
  vpc_id      = data.terraform_remote_state.aws_base.outputs.vpc_id

  ingress {
    description = "PostgreSQL access from VPC CIDR"
    from_port   = var.db_port
    to_port     = var.db_port
    protocol    = "tcp"
    cidr_blocks = [data.terraform_remote_state.aws_base.outputs.vpc_cidr]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = local.secgrp_rds_name
  }
}
