resource "aws_instance" "bastion" {

  ami           = lookup(var.BASTION_AMI, var.AWS_REGION)
  instance_type = var.BASTION_TYPE

  # VPC
  subnet_id = aws_subnet.prod-subnet-public.id

  # Security Group
  vpc_security_group_ids = [
    aws_security_group.bastion.id,
  ]

  # the Public SSH key
  key_name = aws_key_pair.ssh-public-key-region-key-pair.id

  connection {
    host        = self.public_ip
    user        = var.EC2_USER
    private_key = file(var.PRIVATE_BASTION_KEY_PATH)
  }

  tags = {
    "Name" = "iForm Bastion Server"
  }
}

resource "aws_key_pair" "ssh-public-key-region-key-pair" {
  key_name   = "ssh-public-key-region-key-pair"
  public_key = file(var.PUBLIC_BASTION_KEY_PATH)
}

output "bastion_host_ip" {
  value = aws_instance.bastion.public_ip
}
