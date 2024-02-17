output "vpc-id" {
  value = aws_vpc.vpc.id
}
output "pubsub1" {
  value = aws_subnet.pubsub1.id
}
output "pubsub2" {
  value = aws_subnet.pubsub2.id
}
output "pubsub3" {
  value = aws_subnet.pubsub3.id
}
output "prvsub1" {
  value = aws_subnet.prtsub1.id
}
output "prvsub2" {
  value = aws_subnet.prtsub2.id
}
output "prvsub3" {
  value = aws_subnet.prtsub3.id
}
output "jenkins-ip" {
  value = aws_instance.jenkins-server.public_ip
}
