resource "aws_iam_instance_profile" "default" {
  name = "default"
  role = aws_iam_role.assumerole.name
}

resource "aws_iam_role" "assumerole" {

  name = "iform-assume-role"

  # a.k.a CloudWatchAgentServerPolicy
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF

  tags = {
    Name = "iForm EC2 Assume Role"
  }
}

resource "aws_iam_policy" "cwagent" {

  name   = "iform-acwlogs-send-logs-policy"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "cloudwatch:PutMetricData",
                "ec2:DescribeVolumes",
                "ec2:DescribeTags",
                "logs:PutLogEvents",
                "logs:DescribeLogStreams",
                "logs:DescribeLogGroups",
                "logs:CreateLogStream",
                "logs:CreateLogGroup"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ssm:GetParameter"
            ],
            "Resource": "arn:aws:ssm:*:*:parameter/AmazonCloudWatch-*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "appserver-policy-role-attachment" {
  role       = aws_iam_role.assumerole.name
  policy_arn = aws_iam_policy.cwagent.arn
}

resource "aws_kms_key" "this" {
}

resource "random_password" "admin_user" {
  length           = 16
  special          = true
  override_special = "*+-./=?[]^_"
}

resource "random_password" "devise_secret_key" {
  length           = 256
  special          = false
  upper            = true
  lower            = true
}

resource "random_password" "secret_key_base" {
  length           = 256
  special          = false
  upper            = true
  lower            = true
}

resource "random_password" "stripe_key" {
  length           = 256
  special          = false
  upper            = true
  lower            = true
}

resource "random_password" "secret_token" {
  length           = 256
  special          = false
  upper            = true
  lower            = true
}

resource "aws_instance" "app" {

  ami           = lookup(var.IFORM_AMI, var.AWS_REGION)
  instance_type = var.IFORM_TYPE

  depends_on = [
    aws_efs_file_system.datalake,
    aws_db_instance.main
  ]

  root_block_device {
    volume_type = "gp2"
    volume_size = 25
    encrypted   = true
    kms_key_id  = aws_kms_key.this.arn
  }

  ebs_block_device {
    delete_on_termination = false
    device_name           = "/dev/sdf"
    volume_type           = "gp2"
    volume_size           = 25
    encrypted             = true
    kms_key_id            = aws_kms_key.this.arn
  }

  iam_instance_profile = aws_iam_instance_profile.default.name

  user_data = templatefile("user-data/app-server.sh", {

    rds_endpoint = trimsuffix(aws_db_instance.main.endpoint, ":${aws_db_instance.main.port}")
    rds_username = aws_db_instance.main.username
    rds_port     = aws_db_instance.main.port
    rds_password = aws_db_instance.main.password
    rds_database = aws_db_instance.main.name

    app_host             = format("%s.%s", var.SUBDOMAIN, var.APP_HOST)
    spp_log_file         = var.SPP_LOG_FILE
    puma_access_log_file = var.PUMA_ACCESS_LOG_FILE
    puma_error_log_file  = var.PUMA_ERROR_LOG_FILE
    smtp_address         = lookup(var.SMTP, "address")
    smtp_port            = lookup(var.SMTP, "port")

    smtp_password = var.SMTP_PASSWORD
    smtp_username = var.SMTP_USERNAME

    from_email     = var.FROM_EMAIL
    admin_password = random_password.admin_user.result

    secret_key_base = random_password.secret_key_base.result
    stripe_key      = random_password.stripe_key.result
    secret_token    = random_password.secret_token.result

    efs_dns_name = aws_efs_file_system.datalake.dns_name

    datalake_mount_point = var.DATALAKE_MOUNT_POINT

    rds_ca_2019_location   = var.RDS_CA_2019_LOCATION
    local_ca_2019_location = var.LOCAL_CA_2019_LOCATION
    devise_secret_key      = random_password.devise_secret_key.result

    subdomain            = var.SUBDOMAIN
    school_title         = var.SCHOOL_TITLE
    school_phone         = var.SCHOOL_PHONE
    school_secret_phrase = var.SCHOOL_SECRET_PHRASE
  })

  subnet_id = aws_subnet.prod-subnet-private.id

  vpc_security_group_ids = [
    aws_security_group.appserver.id,
  ]

  # the Public SSH key
  key_name = aws_key_pair.ssh-key-region-key-pair.id

  connection {
    host        = self.private_ip
    user        = var.EC2_USER
    private_key = file(var.PRIVATE_KEY_PATH)
  }

  tags = {
    "Name" = "iForm App Server"
  }
}

resource "aws_key_pair" "ssh-key-region-key-pair" {
  key_name   = "ssh-key-region-key-pair"
  public_key = file(var.PUBLIC_KEY_PATH)
}

output "appserver_host_ip" {
  value = aws_instance.app.private_ip
}
