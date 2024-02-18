output "masternode-ip" {
  value = aws_instance.masternode.*.private_ip
}

output "masternode-ids" {
  value = aws_instance.masternode.*.id
}