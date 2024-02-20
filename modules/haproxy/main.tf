# Creating haproxy1 server
resource "aws_instance" "haproxy1" {
  ami = var.ami
  instance_type = var.instance_type
  subnet_id = var.ha-subnet
  vpc_security_group_ids = [var.haproxy-sg]
  key_name = var.keyname
  user_data = templatefile("./modules/haproxy/ha-proxy1.sh", {
    master1 = var.master1
    master2 = var.master2
    master3 = var.master3
})
  tags = {
    Name = var.ha-proxy1-tag
  }
}

# Creating haproxy2 server
resource "aws_instance" "haproxy2" {
  ami = var.ami
  instance_type = var.instance_type
  subnet_id = var.ha-subnet2
  vpc_security_group_ids = [var.haproxy-sg]
  key_name = var.keyname
  user_data = templatefile("./modules/haproxy/ha-proxy1.sh", {
    master1 = var.master1
    master2 = var.master2
    master3 = var.master3
})
  tags = {
    Name = var.ha-proxy2-tag
  }
}