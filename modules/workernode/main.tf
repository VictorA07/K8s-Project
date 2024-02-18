# Creating masternode server
resource "aws_instance" "workernode" {
  ami = var.ami
  count = var.instance-count
  instance_type = var.instance_type
  vpc_security_group_ids = [var.worker-sg]
  subnet_id = element(var.prvsub-id, count.index)
  key_name = var.keyname
  
  tags = {
    Name = "${var.instance-name}${count.index}"
  }
}