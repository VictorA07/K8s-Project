output "vpc-id" {
  value = aws_vpc.vpc.id
}
output "pubsub1" {
  value = aws_subnet.pubsub[0].id
}
output "pubsub2" {
  value = aws_subnet.pubsub[1].id
}
output "pubsub3" {
  value = aws_subnet.pubsub[2].id
}
output "prvsub1" {
  value = aws_subnet.prtsub[0].id
}
output "prvsub2" {
  value = aws_subnet.prtsub[1].id
}
output "prvsub3" {
  value = aws_subnet.prtsub[2].id
}
output "jenkins--active-pubip" {
  value = aws_instance.jenkins-server-active.public_ip
}
output "jenkins-passive-pubip" {
  value = aws_instance.jenkins-server-passive.public_ip
}
output "haproxy-ip" {
  value = aws_instance.haproxy-server.public_ip
}
output "efs-ip" {
  value = aws_efs_file_system.jenkins-efs.id
}
