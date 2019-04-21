
```ruby
variable "domain" {
  description = "Route 53 で管理しているドメイン名"
  type        = "string"

  #FIXME:
  default = "poncotu.net"
}

data "aws_route53_zone" "main" {
  #XXX:
  name         = "${var.domain}"
  private_zone = false
}

resource "aws_acm_certificate" "main" {
  domain_name = "${var.domain}"

  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "validation" {
  depends_on = ["aws_acm_certificate.main"]

  zone_id = "${data.aws_route53_zone.main.id}"

  ttl = 60

  name    = "${aws_acm_certificate.main.domain_validation_options.0.resource_record_name}"
  type    = "${aws_acm_certificate.main.domain_validation_options.0.resource_record_type}"
  records = ["${aws_acm_certificate.main.domain_validation_options.0.resource_record_value}"]
}

resource "aws_acm_certificate_validation" "main" {
  certificate_arn = "${aws_acm_certificate.main.arn}"

  validation_record_fqdns = ["${aws_route53_record.validation.0.fqdn}"]
}

resource "aws_route53_record" "main" {
  type = "A"

  name    = "${var.domain}"
  zone_id = "${data.aws_route53_zone.main.id}"

  alias = {
    name                   = "${aws_lb.main.dns_name}"
    zone_id                = "${aws_lb.main.zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_security_group_rule" "alb_https" {
  security_group_id = "${aws_security_group.alb.id}"

  type = "ingress"

  from_port = 443
  to_port   = 443
  protocol  = "tcp"

  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = "${aws_lb.main.arn}"

  certificate_arn = "${aws_acm_certificate.main.arn}"

  port     = "443"
  protocol = "HTTPS"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.main.id}"
  }
}

resource "aws_lb_listener_rule" "http_to_https" {
  listener_arn = "${aws_lb_listener.main.arn}"

  priority = 99

  action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  condition {
    field  = "host-header"
    values = ["${var.domain}"]
  }
}
```
