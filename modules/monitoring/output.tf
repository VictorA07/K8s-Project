output "grafana-dns-name" {
  value = aws_lb.grafana-lb.dns_name
}
output "grafana-zone-id" {
  value = aws_lb.grafana-lb.zone_id
}
output "prom-dns-name" {
  value = aws_lb.prom-lb.dns_name
}
output "prom-zone-id" {
  value = aws_lb.prom-lb.zone_id
}