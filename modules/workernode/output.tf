output "workernode-ip" {
  value = aws_instance.workernode.*.private_ip
}

output "workernode-ids" {
  value = aws_instance.workernode.*.id
}