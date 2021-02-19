# security group
resource "aws_security_group" "appserver" {

  vpc_id = aws_vpc.prod-vpc.id

  dynamic "egress" {

    for_each = var.APP_SERVER_PUBLIC_EGRESS_PORTS

    content {
      from_port   = egress.value
      to_port     = egress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  # http request
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.loadbalancer.id]
  }

  # ssh
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  tags = {
    Name = "App Server"
  }
}

resource "aws_security_group" "loadbalancer" {

  vpc_id = aws_vpc.prod-vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # used only for HTTPS redirect
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Load Balancer"
  }
}

resource "aws_security_group" "bastion" {

  vpc_id = aws_vpc.prod-vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = var.BASTION_SSH_CIDR_BLOCKS
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.BASTION_SSH_CIDR_BLOCKS
  }

  tags = {
    Name = "Bastion Host"
  }
}

resource "aws_security_group" "postgres" {

  vpc_id = aws_vpc.prod-vpc.id

  egress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.appserver.id]
  }

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.appserver.id]
  }

  tags = {
    Name = "Postgres"
  }
}

resource "aws_security_group" "ses" {

  vpc_id = aws_vpc.prod-vpc.id

  egress {
    from_port       = lookup(var.SMTP, "port")
    to_port         = lookup(var.SMTP, "port")
    protocol        = "tcp"
    security_groups = [aws_security_group.appserver.id]
  }

  ingress {
    from_port       = lookup(var.SMTP, "port")
    to_port         = lookup(var.SMTP, "port")
    protocol        = "tcp"
    security_groups = [aws_security_group.appserver.id]
  }

  tags = {
    Name = "SES SG"
  }
}
