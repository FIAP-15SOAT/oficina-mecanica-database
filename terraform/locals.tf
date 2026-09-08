locals {
  rds_identifier       = "rds-${var.project_name}"
  db_subnet_group_name = "dbsng-${var.project_name}"
  secgrp_rds_name      = "secgrp-rds-${var.project_name}"

  db_credentials_secret_name = "${var.project_name}/database/credentials"
}
