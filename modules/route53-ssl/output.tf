output "stage" {
  value = aws_route53_record.stage-record.id
}
output "prod" {
  value = aws_route53_record.prod-record.id
}
output "grafana" {
  value = aws_route53_record.grafana-record.id
}
output "prom" {
  value = aws_route53_record.prom-record.id
}
output "route53-zone" {
  value = data.aws_route53_zone.route53-zone.id
}
output "ssl-cert" {
  value = aws_acm_certificate.ssl-cert.arn
}