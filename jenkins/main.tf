resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "${var.project-name}-vpc"
  }
}

resource "aws_subnet" "pubsub" {
  count = 3
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = element(var.public-subnets, count.index)
  availability_zone = element(var.availability-zones, count.index)

  tags = {
    Name = "${var.project-name}-pubsub${count.index}"
  }
}
resource "aws_subnet" "prtsub" {
  count = 3
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = element(var.private-subnets, count.index)
  availability_zone = element(var.availability-zones, count.index)

  tags = {
    Name = "${var.project-name}-prtsub${count.index}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.project-name}-igw"
  }
}

resource "aws_route_table" "pubrt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name : "${var.project-name}-pubrt"
  }
}

resource "aws_route_table_association" "pubrt-ass" {
  count = 3
  route_table_id = aws_route_table.pubrt.id
  subnet_id      = aws_subnet.pubsub[count.index].id
}

resource "aws_eip" "eip" {
  domain = "vpc"
  tags = {
    Name = "${var.project-name}-eip"
  }
}
resource "aws_nat_gateway" "nat-gw" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.pubsub[0].id
  tags = {
    Name = "${var.project-name}-nat-gw"
  }
}
resource "aws_route_table" "prvrt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gw.id
  }
  tags = {
    Name = "${var.project-name}-prvrt"
  }
}
resource "aws_route_table_association" "prvrt-ass" {
  count = 3
  route_table_id = aws_route_table.prvrt.id
  subnet_id      = aws_subnet.prtsub[count.index].id
}

resource "aws_security_group" "jenkins-sg" {
  description = "jenkins-security-group"
  name        = "jenkins"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    description = "ssh port"
    from_port   = "${var.ssh-port}"
    to_port     = "${var.ssh-port}"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "ssh port"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "jenkins port"
    from_port   = "${var.jenkins-port}"
    to_port     = "${var.jenkins-port}"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.project-name}-jenkins-sg"
  }
}
resource "aws_security_group" "efs-sg" {
  description = "efs-security-group"
  name        = "efs-sg"
  vpc_id      = aws_vpc.vpc.id
  
  ingress {
    description = "efs port"
    from_port   = "${var.efs-port}"
    to_port     = "${var.efs-port}"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_groups = [aws_security_group.jenkins-sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    security_groups = [aws_security_group.jenkins-sg.id]
  }
  tags = {
    Name = "${var.project-name}-jenkins-sg"
  }
}

resource "tls_private_key" "keypair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "keypair" {
  content         = tls_private_key.keypair.private_key_pem
  filename        = "jenkins-keypair.pem"
  file_permission = "600"
}
resource "aws_key_pair" "keypair" {
  key_name   = "jenkins-keypair"
  public_key = tls_private_key.keypair.public_key_openssh
}
resource "aws_efs_file_system" "jenkins-efs" {
  creation_token = "jenkins-backup"
  performance_mode = "generalPurpose"
  throughput_mode = "bursting"
  lifecycle_policy {
    transition_to_ia = "AFTER_7_DAYS"
  }
  tags = {
    Name = "jenkins-backup"
  }
}
resource "aws_efs_mount_target" "jenkins-mtg" {
  count = 2
  file_system_id = aws_efs_file_system.jenkins-efs.id
  subnet_id      = element(aws_subnet.pubsub[*].id, count.index)  #Change to VPC module if it does not work
  security_groups = [aws_security_group.efs-sg.id]
}

resource "aws_instance" "jenkins-server-active" {
  ami                         = "${var.ami-ec2}"
  instance_type               = "${var.instance-type}"
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.jenkins-sg.id]
  subnet_id                   = aws_subnet.pubsub[0].id
  iam_instance_profile        = aws_iam_instance_profile.ec2-profile.id
  key_name                    = aws_key_pair.keypair.id
  user_data                   = local.jenkins-userdata

  tags = {
    Name = "${var.project-name}-jenkins-server-active"
  }
  depends_on = [ aws_efs_mount_target.jenkins-mtg ]
}

resource "aws_instance" "jenkins-server-passive" {
  ami                         = "${var.ami-ec2}"
  instance_type               = "${var.instance-type}"
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.jenkins-sg.id]
  subnet_id                   = aws_subnet.pubsub[1].id
  iam_instance_profile        = aws_iam_instance_profile.ec2-profile.id
  key_name                    = aws_key_pair.keypair.id
  user_data                   = local.jenkins-userdata2

  tags = {
    Name = "${var.project-name}-jenkins-server-passive"
  }
  depends_on = [ aws_efs_mount_target.jenkins-mtg ]
}
resource "aws_instance" "haproxy-server" {
  ami                         = "${var.ami-ubuntu}"
  instance_type               = "${var.instance-type}"
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.jenkins-sg.id]
  subnet_id                   = aws_subnet.pubsub[2].id
  iam_instance_profile        = aws_iam_instance_profile.ec2-profile.id
  key_name                    = aws_key_pair.keypair.id
  user_data                   = local.haproxy-data

  tags = {
    Name = "${var.project-name}-haproxy-server"
  }
}

resource "aws_iam_instance_profile" "ec2-profile" {
  name = "ec2-profile2"
  role = aws_iam_role.ec2-role.name
}
resource "aws_iam_role" "ec2-role" {
  name               = "ec2-role2"
  assume_role_policy = "${file("${path.root}/ec2-assume.json")}"
}
resource "aws_iam_role_policy_attachment" "ec2-policy-attachment" {
  policy_arn = "${var.iam-policy-arn}"
  role       = aws_iam_role.ec2-role.name
}

resource "null_resource" "credentials" {
  depends_on = [aws_instance.jenkins-server-active]
  provisioner "local-exec" {
    command = <<-EOT
      ids_output=$(terraform output)
      printf '%s\n' "$ids_output" | awk '{print "  " $0}' | sed '3r /dev/stdin' ../main.tf > tmpfile && mv tmpfile ../main.tf
    EOT 
  }
}