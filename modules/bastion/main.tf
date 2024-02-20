#Creating baston host server
resource "aws_instance" "bastion-server" {
  ami = var.ami
  instance_type = var.instance_type
  vpc_security_group_ids = [var.bastion-sg]
  subnet_id = var.subnet-id
  associate_public_ip_address = true
  key_name = var.keyname
  user_data = templatefile("./modules/bastion/bastion.sh", {
      private-key = var.private-key
  })
  tags = {
    Name =   var.server-name
  }
}
