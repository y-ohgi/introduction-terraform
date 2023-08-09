variable "name" {
  type = string
}

variable "domain" {
  type = string
}

data "aws_route53_zone" "this" {
  name         = var.domain
  private_zone = false
}

resource "aws_acm_certificate" "this" {
  domain_name = var.domain

  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "this" {
  depends_on = [aws_acm_certificate.this]

  zone_id = data.aws_route53_zone.this.id

  ttl = 60

  for_each = {
    for dvo in aws_acm_certificate.this.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  name    = each.value.name
  records = [each.value.record]
  type    = each.value.type
}

resource "aws_acm_certificate_validation" "this" {
  certificate_arn = aws_acm_certificate.this.arn

  validation_record_fqdns = [for record in aws_route53_record.this : record.fqdn]
}

output "acm_id" {
  value = aws_acm_certificate.this.id
}
