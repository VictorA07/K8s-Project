output "bas-ans-sg" {
  value = aws_security_group.bas-ans-sg.id
}
output "kube-sg" {
  value = aws_security_group.kube-sg.id
}
output "keypair-id" {
  value = aws_key_pair.keypair.id
}
output "private-key" {
  value = tls_private_key.keypair.private_key_pem
}