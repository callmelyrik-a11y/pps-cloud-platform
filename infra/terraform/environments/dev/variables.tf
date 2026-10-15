variable "region" {
  type    = string
  default = "ap-northeast-2"
}

variable "project" {
  type    = string
  default = "pps"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "availability_zones" {
  type    = list(string)
  default = ["ap-northeast-2a", "ap-northeast-2b"]

  validation {
    condition     = length(var.availability_zones) == 2 && var.availability_zones[0] != var.availability_zones[1]
    error_message = "Choose two distinct AZs available in your AWS account."
  }
}

variable "cluster_version" {
  description = "Check supported EKS versions in ap-northeast-2 before apply."
  type        = string
  default     = "1.34"
}

variable "node_instance_type" {
  type    = string
  default = "t3.medium"
}

variable "node_min_size" {
  type    = number
  default = 2
}

variable "node_desired_size" {
  type    = number
  default = 2
}

variable "node_max_size" {
  type    = number
  default = 4
}

variable "eks_admin_principal_arn" {
  description = "Optional IAM user or role ARN that needs kubectl administrator access."
  type        = string
  default     = null
}

variable "cluster_public_access_cidrs" {
  description = "Allowlist for public Kubernetes API access; restrict for real use."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "aurora_engine_version" {
  description = "Aurora MySQL version supporting Serverless v2 in the chosen region. Verify before applying."
  type        = string
  default     = "8.0.mysql_aurora.3.10.3"
}

variable "aurora_min_acu" {
  type    = number
  default = 0.5
}

variable "aurora_max_acu" {
  type    = number
  default = 2.0
}

variable "frontend_bucket_name" {
  description = "Globally unique S3 bucket name (e.g., pps-dev-frontend-YOUR_ACCOUNT_ID)."
  type        = string
}

variable "alarm_email" {
  description = "Optional email address for CloudWatch SNS alarm notifications."
  type        = string
  default     = null
}

variable "alb_controller_policy_arn" {
  description = "Optional AWS Load Balancer Controller IAM policy ARN; policy must be provisioned following AWS official installation instructions."
  type        = string
  default     = null
}

variable "public_domain_name" {
  description = "Optional actual frontend FQDN in a hosted zone you control."
  type        = string
  default     = null

  validation {
    condition     = (var.public_domain_name == null) == (var.hosted_zone_id == null)
    error_message = "Set public_domain_name and hosted_zone_id together, or leave both unset."
  }
}

variable "hosted_zone_id" {
  description = "Route 53 PUBLIC hosted zone ID for public_domain_name; supply both or neither."
  type        = string
  default     = null
}
