output "ansible" {
  value = module.ansible.ansible-ip
}
output "bastion" {
  value = module.bastion.bastion-ip
}
output "haproxy1" {
  value = module.haproxy.haproxy1_private_ip
}
output "haproxy2" {
  value = module.haproxy.haproxy2_private_ip
}
output "masternode" {
  value = module.masternode.masternode-ip
}
output "workernode" {
  value = module.workernode.workernode-ip
}