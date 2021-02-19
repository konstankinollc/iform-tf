resource "aws_efs_file_system" "datalake" {

  creation_token = "iform-datalake"
  encrypted      = true

  tags = {
    Name = "iForm File storage"
  }
}

resource "aws_efs_mount_target" "efs-mount-datalake" {
  file_system_id = aws_efs_file_system.datalake.id
  subnet_id      = aws_subnet.prod-subnet-private.id
  security_groups = [
    aws_security_group.datalake.id
  ]
}

resource "aws_efs_mount_target" "efs-mount-2-datalake" {
  file_system_id = aws_efs_file_system.datalake.id
  subnet_id      = aws_subnet.prod-subnet-private-2.id
  security_groups = [
    aws_security_group.datalake.id
  ]
}

resource "aws_security_group" "datalake" {

  vpc_id = aws_vpc.prod-vpc.id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.appserver.id]
  }

  egress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.appserver.id]
  }

  tags = {
    Name = "EFS"
  }
}

output "datalake" {
  value = aws_efs_file_system.datalake.dns_name
}
