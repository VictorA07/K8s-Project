output "stage-dns-name" {
  value = aws_lb.stage-lb.dns_name
}
output "stage-zone-id" {
  value = aws_lb.stage-lb.zone_id
}
output "prod-dns-name" {
  value = aws_lb.prod-lb.dns_name
}
output "prod-zone-id" {
  value = aws_lb.prod-lb.zone_id
}