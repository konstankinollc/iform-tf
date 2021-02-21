resource "aws_db_subnet_group" "private-subnet" {

  name = "iform-main"
  subnet_ids = [
    aws_subnet.prod-subnet-private.id,
    aws_subnet.prod-subnet-private-2.id,
    aws_subnet.prod-subnet-private-3.id,
  ]

  tags = {
    "Name" = "Subnet Group for iForm database"
  }
}

resource "aws_db_instance" "main" {

  depends_on = [aws_db_subnet_group.private-subnet]

  engine            = lookup(var.DATABASE_INSTANCE, "engine")
  engine_version    = lookup(var.DATABASE_INSTANCE, "engine_version")
  instance_class    = lookup(var.DATABASE_INSTANCE, "instance_class")
  allocated_storage = lookup(var.DATABASE_INSTANCE, "allocated_storage")
  storage_type      = "gp2"
  storage_encrypted = true

  db_subnet_group_name   = aws_db_subnet_group.private-subnet.id
  vpc_security_group_ids = [aws_security_group.postgres.id]

  name     = var.DB_NAME
  username = var.DB_USERNAME
  password = var.DB_PASSWORD
  port     = var.DB_PORT

  availability_zone = "${var.AWS_REGION}a"
  multi_az          = lookup(var.DATABASE_INSTANCE, "multi_az")

  publicly_accessible         = false
  allow_major_version_upgrade = false
  auto_minor_version_upgrade  = true
  apply_immediately           = true
  copy_tags_to_snapshot       = true

  delete_automated_backups  = lookup(var.DATABASE_INSTANCE, "delete_automated_backups")
  deletion_protection       = lookup(var.DATABASE_INSTANCE, "deletion_protection")
  skip_final_snapshot       = lookup(var.DATABASE_INSTANCE, "skip_final_snapshot")
  backup_retention_period   = lookup(var.DATABASE_INSTANCE, "backup_retention_period")
  final_snapshot_identifier = lookup(var.DATABASE_INSTANCE, "final_snapshot_identifier")
  max_allocated_storage     = lookup(var.DATABASE_INSTANCE, "max_storage")
  ca_cert_identifier        = lookup(var.DATABASE_INSTANCE, "rds_ca")

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  maintenance_window              = "Mon:00:00-Mon:03:00"
  backup_window                   = "03:00-06:00"

  tags = {
    "Name" = "iForm App Main"
  }

  timeouts {
    create = "40m"
    delete = "80m"
    update = "40m"
  }
}

# output "rds_host_endpoint" {
#   value = aws_db_instance.main.endpoint
# }
