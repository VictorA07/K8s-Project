locals {
  name = "k8s-project"

}
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "${local.name}-vpc"
  }
}

resource "aws_subnet" "pubsub1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-west-2a"

  tags = {
    Name = "${local.name}-pubsub1"
  }
}

resource "aws_subnet" "pubsub2" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-west-2b"

  tags = {
    Name = "${local.name}-pubsub2"
  }
}

resource "aws_subnet" "pubsub3" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "eu-west-2c"

  tags = {
    Name = "${local.name}-pubsub3"
  }
}

resource "aws_subnet" "prtsub1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "eu-west-2a"

  tags = {
    Name = "${local.name}-prtsub1"
  }
}

resource "aws_subnet" "prtsub2" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.5.0/24"
  availability_zone = "eu-west-2b"

  tags = {
    Name = "${local.name}-prtsub2"
  }
}

resource "aws_subnet" "prtsub3" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.6.0/24"
  availability_zone = "eu-west-2c"

  tags = {
    Name = "${local.name}-prtsub3"
  }
}
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${local.name}-igw"
  }
}

resource "aws_route_table" "pubrt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name : "${local.name}-pubrt"
  }
}

resource "aws_route_table_association" "pubrt-ass-1" {
  route_table_id = aws_route_table.pubrt.id
  subnet_id      = aws_subnet.pubsub1.id
}
resource "aws_route_table_association" "pubrt-ass-2" {
  route_table_id = aws_route_table.pubrt.id
  subnet_id      = aws_subnet.pubsub2.id
}
resource "aws_route_table_association" "pubrt-ass-3" {
  route_table_id = aws_route_table.pubrt.id
  subnet_id      = aws_subnet.pubsub3.id
}
resource "aws_eip" "eip" {
  domain = "vpc"
  tags = {
    Name = "${local.name}-eip"
  }
}
resource "aws_nat_gateway" "nat-gw" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.prtsub1.id
  tags = {
    Name = "${local.name}-nat-gw"
  }
}
resource "aws_route_table" "prvrt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gw.id
  }
  tags = {
    Name = "${local.name}-prvrt"
  }
}
resource "aws_route_table_association" "prvrt-ass-1" {
  route_table_id = aws_route_table.prvrt.id
  subnet_id      = aws_subnet.prtsub1.id
}
resource "aws_route_table_association" "prvrt-ass-2" {
  route_table_id = aws_route_table.prvrt.id
  subnet_id      = aws_subnet.prtsub2.id
}
resource "aws_route_table_association" "prvrt-ass-3" {
  route_table_id = aws_route_table.prvrt.id
  subnet_id      = aws_subnet.prtsub3.id
}
resource "aws_security_group" "jenkins-sg" {
  description = "jenkins-security-group"
  name        = "jenkins"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    description = "ssh port"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "jenkins port"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${local.name}-jenkins-sg"
  }
}

resource "tls_private_key" "keypair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "keypair" {
  content         = tls_private_key.keypair.private_key_pem
  filename        = "jenkins-keypair.pem"
  file_permission = 600
}
resource "aws_key_pair" "keypair" {
  key_name   = "jenkins-keypair"
  public_key = tls_private_key.keypair.public_key_openssh
}

resource "aws_instance" "jenkins-server" {
  ami                         = "ami-0e5f882be1900e43b"
  instance_type               = "t2.medium"
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.jenkins-sg.id]
  subnet_id                   = aws_subnet.prtsub1.id
  iam_instance_profile        = aws_iam_instance_profile.ec2-profile.id
  key_name                    = aws_key_pair.keypair.id
  user_data                   = local.jenkins-userdata

  tags = {
    Name = "${local.name}-jenkins-server"
  }
}

resource "aws_iam_instance_profile" "ec2-profile" {
  name = "ec2-profile2"
  role = aws_iam_role.ec2-role.name
}
resource "aws_iam_role" "ec2-role" {
  name               = "ec2-role2"
  assume_role_policy = file("${path.root}/ec2-assume.json")
}
resource "aws_iam_role_policy_attachment" "ec2-policy-attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  role       = aws_iam_role.ec2-role.name
}

resource "null_resource" "credentials" {
  depends_on = [aws_instance.jenkins-server]
  provisioner "local-exec" {
    command = <<-EOT
      ids_output=$(terraform output)
      printf '%s\n' "$ids_output" | awk '{print "  " $0}' | sed '3r /dev/stdin' ../main.tf > tmpfile && mv tmpfile ../main.tf
    EOT 
  }
}