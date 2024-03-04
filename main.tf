locals {
  name = "K8s-servers"
  
  docker-dns = "ec2-18-134-198-197.eu-west-2.compute.amazonaws.com"
  docker-ip = "18.134.198.197"
  efs-ip = "fs-0aeef9ea65bbc7c39"
  prvsub1 = "subnet-03fd64b5578d45937"
  prvsub2 = "subnet-0b7e2749ad449ef4d"
  prvsub3 = "subnet-04b5563ab16c1c5b5"
  pubsub1 = "subnet-08d9ac704cad94006"
  pubsub2 = "subnet-0bafc6f2d998a5d17"
  pubsub3 = "subnet-0591a627ba8f78427"
  vpc-id = "vpc-0fb6e38d8ca639d0d"
}
data "aws_vpc" "vpc" {
  id = local.vpc-id
}
data "aws_subnet" "prvsub1" {
  id = local.prvsub1
}
data "aws_subnet" "prvsub2" {
  id = local.prvsub2
}
data "aws_subnet" "prvsub3" {
  id = local.prvsub3
}
data "aws_subnet" "pubsub1" {
  id = local.pubsub1
}
data "aws_subnet" "pubsub2" {
  id = local.pubsub2
}
data "aws_subnet" "pubsub3" {
  id = local.pubsub3
}

module "key-sg" {
  source     = "./modules/key-sg"
  vpc-id     = data.aws_vpc.vpc.id
  kube-sg    = "${local.name}-kube-sg"
  bas-ans-sg = "${local.name}-bas-ans-sg"
}

module "ansible" {
  source        = "./modules/ansible"
  ami           = "ami-0e5f882be1900e43b"
  instance_type = "t2.medium"
  subnet-id     = data.aws_subnet.prvsub2.id
  ansible-sg    = [module.key-sg.bas-ans-sg]
  keyname       = module.key-sg.keypair-id
  private-key   = module.key-sg.private-key
  haproxy1      = module.haproxy.haproxy1_private_ip
  haproxy2      = module.haproxy.haproxy2_private_ip
  main-master   = module.masternode.masternode-ip[0]
  main-master01 = module.masternode.masternode-ip[1]
  main-master02 = module.masternode.masternode-ip[2]
  worker01      = module.workernode.workernode-ip[0]
  worker02      = module.workernode.workernode-ip[1]
  worker03      = module.workernode.workernode-ip[2]
  bastion-host  = module.bastion.bastion-ip
  server-name   = "${local.name}-ansible"
}

module "bastion" {
  source        = "./modules/bastion"
  ami           = "ami-0e5f882be1900e43b"
  instance_type = "t2.micro"
  bastion-sg    = module.key-sg.bas-ans-sg
  subnet-id     = data.aws_subnet.pubsub1.id
  keyname       = module.key-sg.keypair-id
  private-key   = module.key-sg.private-key
  server-name   = "${local.name}-bastion"
}

module "environment" {
  source          = "./modules/environment"
  stage-lb-tag    = "${local.name}-stage-lb"
  lb-sg           = [module.key-sg.kube-sg]
  stage-tg-tag    = "${local.name}-stage-tg"
  vpc-id          = data.aws_vpc.vpc.id
  instance        = module.workernode.workernode-ids
  certificate_arn = module.route53-ssl.ssl-cert
  lb-subnet       = [data.aws_subnet.pubsub1.id, data.aws_subnet.pubsub2.id, data.aws_subnet.pubsub3.id]
  prod-alb-tag    = "${local.name}-prod-alb"
  prod-tg-tag     = "${local.name}-prod-tg"
}

module "haproxy" {
  source        = "./modules/haproxy"
  ami           = "ami-0e5f882be1900e43b"
  instance_type = "t2.medium"
  ha-subnet     = data.aws_subnet.prvsub1.id
  ha-subnet2    = data.aws_subnet.prvsub2.id
  haproxy-sg    = module.key-sg.kube-sg
  keyname       = module.key-sg.keypair-id
  master1       = module.masternode.masternode-ip[0]
  master2       = module.masternode.masternode-ip[1]
  master3       = module.masternode.masternode-ip[2]
  ha-proxy1-tag = "${local.name}-haproxy1"
  ha-proxy2-tag = "${local.name}-haproxy2"
}

module "masternode" {
  source         = "./modules/masternode"
  ami            = "ami-0e5f882be1900e43b"
  instance-count = "3"
  instance_type  = "t2.medium"
  master-sg      = module.key-sg.kube-sg
  keyname        = module.key-sg.keypair-id
  prvsub-id      = [data.aws_subnet.prvsub1.id, data.aws_subnet.prvsub2.id, data.aws_subnet.prvsub3.id]
  instance-name  = "${local.name}-masternode"
}

module "workernode" {
  source         = "./modules/workernode"
  ami            = "ami-0e5f882be1900e43b"
  instance-count = "3"
  instance_type  = "t2.medium"
  worker-sg      = module.key-sg.kube-sg
  keyname        = module.key-sg.keypair-id
  prvsub-id      = [data.aws_subnet.prvsub1.id, data.aws_subnet.prvsub2.id, data.aws_subnet.prvsub3.id]
  instance-name  = "${local.name}-workernode"
}

module "monitoring" {
  source          = "./modules/monitoring"
  grafana-lb-tag  = "${local.name}-grafana-lb"
  grafana-tg-tag  = "${local.name}-grafana-tg"
  prom-lb-tag     = "${local.name}-prom-lb"
  prom-tg-tag     = "${local.name}-prom-tg"
  kube-sg         = [module.key-sg.kube-sg]
  kube-subnet     = [data.aws_subnet.prvsub1.id, data.aws_subnet.prvsub2.id, data.aws_subnet.prvsub3.id]
  vpc-id          = data.aws_vpc.vpc.id
  instance        = module.workernode.workernode-ids
  certificate_arn = module.route53-ssl.ssl-cert
}

module "route53-ssl" {
  source           = "./modules/route53-ssl"
  domain-name      = "greatminds.sbs"
  stage-dns-name   = module.environment.stage-dns-name
  stage-zone-id    = module.environment.stage-zone-id
  prod-dns-name    = module.environment.prod-dns-name
  prod-zone-id     = module.environment.prod-zone-id
  grafana-dns-name = module.monitoring.grafana-dns-name
  grafana-zone-id  = module.monitoring.grafana-zone-id
  prom-dns-name    = module.monitoring.prom-dns-name
  prom-zone-id     = module.monitoring.prom-zone-id
}