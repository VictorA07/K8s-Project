#Creating route53 hosted zone
data "aws_route53_zone" "route53-zone" {
  name = var.domain-name
  private_zone = false
}
#Creating Record for stage
resource "aws_route53_record" "stage-record" {
  zone_id = data.aws_route53_zone.route53-zone.id
  name = "stage.${data.aws_route53_zone.route53-zone.name}"
  type = "A"
  alias {
    name = var.stage-dns-name
    zone_id = var.stage-zone-id
    evaluate_target_health = false
  }
}

#Creating Record for prod
resource "aws_route53_record" "prod-record" {
  zone_id = data.aws_route53_zone.route53-zone.id
  name = "prod.${data.aws_route53_zone.route53-zone.name}"
  type = "A"
  alias {
    name = var.prod-dns-name
    zone_id = var.prod-zone-id
    evaluate_target_health = false
  }
}
#Creating Record for grafana
resource "aws_route53_record" "grafana-record" {
  zone_id = data.aws_route53_zone.route53-zone.id
  name = "graf.${data.aws_route53_zone.route53-zone.name}"
  type = "A"
  alias {
    name = var.grafana-dns-name
    zone_id = var.grafana-zone-id
    evaluate_target_health = false
  }
}
#Creating Record for prometheus
resource "aws_route53_record" "prom-record" {
  zone_id = data.aws_route53_zone.route53-zone.id
  name = "prom.${data.aws_route53_zone.route53-zone.name}"
  type = "A"
  alias {
    name = var.prom-dns-name
    zone_id = var.prom-zone-id
    evaluate_target_health = false
  }
}
#SSL certificate
resource "aws_acm_certificate" "ssl-cert" {
  domain_name = data.aws_route53_zone.route53-zone.name
  subject_alternative_names = ["*.${data.aws_route53_zone.route53-zone.name}"]
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}
#Creating Route53 validation
resource "aws_route53_record" "route53-record"{
  for_each = {
    for dvo in aws_acm_certificate.ssl-cert.domain_validation_options : dvo.domain_name =>{
        name = dvo.resource_record_name
        record = dvo.resource_record_value
        type = dvo.resource_record_type
    }
  }
  allow_overwrite = true
  name = each.value.name
  records = [each.value.record]
  ttl = 60
  type = each.value.type
  zone_id = data.aws_route53_zone.route53-zone.zone_id
}
#SSL validation
resource "aws_acm_certificate_validation" "ssl-validation" {
  certificate_arn = aws_acm_certificate.ssl-cert.arn
  validation_record_fqdns = [for record in aws_route53_record.route53-record : record.fqdn]
}