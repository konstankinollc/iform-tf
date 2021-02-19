resource "aws_vpc_endpoint" "ses" {

  vpc_id            = aws_vpc.prod-vpc.id
  service_name      = "com.amazonaws.${var.AWS_REGION}.email-smtp"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.ses.id,
  ]

  subnet_ids = [
    aws_subnet.prod-subnet-private.id,
    aws_subnet.prod-subnet-private-2.id
  ]

  private_dns_enabled = true
}
