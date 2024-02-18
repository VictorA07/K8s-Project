output "bastion-ip" {
  value = aws_instance.bastion-server.public_ip
}