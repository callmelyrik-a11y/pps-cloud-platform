# Optional domain: enabled ONLY if both public_domain_name and hosted_zone_id are set.
# CloudFront certificates must be issued in us-east-1.
resource "aws_acm_certificate" "frontend" {
  count             = local.custom_domain_enabled ? 1 : 0
  provider          = aws.us_east_1
  domain_name       = var.public_domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "frontend_certificate_validation" {
  count   = local.custom_domain_enabled ? 1 : 0
  zone_id = var.hosted_zone_id
  name    = tolist(aws_acm_certificate.frontend[0].domain_validation_options)[0].resource_record_name
  type    = tolist(aws_acm_certificate.frontend[0].domain_validation_options)[0].resource_record_type
  ttl     = 60
  records = [tolist(aws_acm_certificate.frontend[0].domain_validation_options)[0].resource_record_value]
}

resource "aws_acm_certificate_validation" "frontend" {
  count                   = local.custom_domain_enabled ? 1 : 0
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.frontend[0].arn
  validation_record_fqdns = [aws_route53_record.frontend_certificate_validation[0].fqdn]
}

resource "aws_route53_record" "frontend_alias" {
  count   = local.custom_domain_enabled ? 1 : 0
  zone_id = var.hosted_zone_id
  name    = var.public_domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.frontend.domain_name
    zone_id                = aws_cloudfront_distribution.frontend.hosted_zone_id
    evaluate_target_health = false
  }
}
