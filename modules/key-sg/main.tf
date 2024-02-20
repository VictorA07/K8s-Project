resource "tls_private_key" "keypair" {
  rsa_bits = 4096
  algorithm = "RSA"
}
resource "aws_key_pair" "keypair" {
  key_name = "server-keypair"
  public_key = tls_private_key.keypair.public_key_openssh
}
resource "local_file" "keypair" {
  content = tls_private_key.keypair.private_key_pem
  filename = "server-keypair.pem"
  file_permission = "660"
}
resource "aws_security_group" "bas-ans-sg" {
  name = var.bas-ans-sg
  description = "Bastion and ansible security group"
  vpc_id = var.vpc-id
  tags = {
    Name = var.bas-ans-sg
  }
}
resource "aws_security_group_rule" "bas-ans-ingress" {
  security_group_id = aws_security_group.bas-ans-sg.id
  type = "ingress"
  from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
resource "aws_security_group_rule" "bas-ans-egress" {
  security_group_id = aws_security_group.bas-ans-sg.id
  type = "egress"
  from_port = 0
  to_port = 0
  protocol = -1
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group" "kube-sg" {
  name = var.kube-sg
  description = "Kubber Security Group"
  vpc_id = var.vpc-id
  tags = {
    Name = var.kube-sg
  }
}
resource "aws_security_group_rule" "kube-ingress" {
  security_group_id = aws_security_group.kube-sg.id
  type = "ingress"
  from_port = 0
  to_port = 65535
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
resource "aws_security_group_rule" "kube-egress" {
  security_group_id = aws_security_group.kube-sg.id
  type = "egress"
  from_port = 0
  to_port = 0
  protocol = -1
  cidr_blocks = ["0.0.0.0/0"]
}