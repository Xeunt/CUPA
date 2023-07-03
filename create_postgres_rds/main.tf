
provider "aws" {
  region = "eu-west-1"
}

data "aws_secretsmanager_secret_version" "the_secret" {
  secret_id = var.secret_id
}

locals {
  secret_string = jsondecode(data.aws_secretsmanager_secret_version.the_secret.secret_string)
}

resource "aws_db_subnet_group" "subnet_group" {
  name        = local.secret_string.subnetgrp_name
  subnet_ids  = local.secret_string.subnet_ids
  description = local.secret_string.subnet_desc
}

resource "aws_db_instance" "rds_instance" {
  identifier                       = local.secret_string.instance_name
  allocated_storage                = 100
  engine                           = local.secret_string.engine
  engine_version                   = local.secret_string.engine_version
  instance_class                   = local.secret_string.inst_class
  username                         = local.secret_string.username
  password                         = local.secret_string.password
  publicly_accessible              = false
  vpc_security_group_ids            = ["${aws_security_group.db-secgrp.id}"]
  db_subnet_group_name             = aws_db_subnet_group.subnet_group.name
  parameter_group_name             = local.secret_string.param_grp_name
  performance_insights_enabled     = true
  performance_insights_retention_period = 7
  maintenance_window               = "Mon:01:00-Mon:03:00"
  backup_window                    = "03:00-04:00"
  backup_retention_period          = 7
  monitoring_interval              = 60
  monitoring_role_arn              = local.secret_string.monitor_arn

  timeouts {
    create = "60m"
  }

  skip_final_snapshot = true
}

resource "aws_security_group" "db-secgrp" {
  name        = local.secret_string.secgrp_name
  description = local.secret_string.secgrp_desc

  vpc_id = local.secret_string.vpc_id
  
  ingress {
    from_port   = local.secret_string.port
    to_port     = local.secret_string.port
    protocol    = "tcp"
    cidr_blocks = local.secret_string.allowed_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = local.secret_string.allowed_cidr_blocks
  }
}

resource "aws_network_acl" "db_nacl" {
  vpc_id = local.secret_string.vpc_id
}

resource "aws_network_acl_rule" "db_inbound_rule" {
  network_acl_id = aws_network_acl.db_nacl.id
  rule_number    = 100
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = false
  cidr_block     = "0.0.0.0/0"
  from_port      = local.secret_string.port
  to_port        = local.secret_string.port
}

resource "aws_network_acl_rule" "db_outbound_rule" {
  network_acl_id = aws_network_acl.db_nacl.id
  rule_number    = 200
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = true
  cidr_block     = "0.0.0.0/0"
  from_port      = local.secret_string.port
  to_port        = local.secret_string.port
}
