# Creating Ansible Server
resource "aws_instance" "ansible-sever" {
  ami = var.ami
  instance_type = var.instance_type
  subnet_id = var.subnet-id
  vpc_security_group_ids = var.ansible-sg
  key_name = var.keyname
  user_data = templatefile("./modules/ansible/userdata.sh",{
    keypair = var.private-key,
    haproxy1 = var.haproxy1,
    haproxy2 = var.haproxy2,
    main-master = var.main-master,
    member-master01 = var.main-master01,
    member-master02 = var.main-master02,
    worker01 = var.worker01,
    worker02 = var.worker02,
    worker03 = var.worker03,
  })
  
  tags = {
    Name =  var.server-name
  }
}

#Creating Null resouces and provisioner (file) to copy ansible playbooks
resource "null_resource" "copy" {
  connection {
    type = "ssh"
    host = aws_instance.ansible-sever.private_ip
    user = "ubuntu"
    private_key = var.private-key
    bastion_host = var.bastion-host
    bastion_user = "ubuntu"
    bastion_private_key = var.private-key
  }
  provisioner "file" {
    source = "./modules/ansible/playbooks"
    destination = "/home/ubuntu/playbooks"
  }
}