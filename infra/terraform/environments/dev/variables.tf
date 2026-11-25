variable "region" {
  type    = string
  default = "ap-northeast-2"
}

variable "project" {
  type    = string
  default = "g2b_konep"
}

variable "g2b_konep_db_master_password" {
  description = "Master password for the Aurora MySQL cluster"
  type        = string
  sensitive   = true
  nullable    = false
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "vpc_cidr" {
  type    = string
  default = "172.30.0.0/16"
}

variable "availability_zones" {
  type    = list(string)
  default = ["ap-northeast-2a", "ap-northeast-2b"]

  validation {
    condition     = length(var.availability_zones) == 2
    error_message = "Choose two distinct AZs available in your AWS account."
  }
}

variable "ubuntu_version" {
  description = "Ubuntu LTS version for EKS worker nodes"
  type        = string
  default     = "24.04"
}

variable "node_architecture" {
  type    = string
  default = "amd64"
}

variable "node_disk_size" {
  type    = number
  default = 40
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
  default = 4
}

variable "node_desired_size" {
  type    = number
  default = 4
}

variable "node_max_size" {
  type    = number
  default = 10
}

variable "eks_admin_principal_arn" {
  description = "Optional IAM user or role ARN that needs kubectl administrator access."
  type        = string
  default     = null
}

## 학원 공인 ip에서만 kube-api 접근 허용
variable "cluster_public_access_cidrs" {
  description = "Allowlist for public Kubernetes API access; restrict for real use."
  type        = list(string)
  default     = ["183.98.32.210/32"]
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
  description = "Optional custom domain for local CloudFront"
  type        = string
  default     = null

  validation {
    condition = (
      (var.public_domain_name == null) ==
      (var.hosted_zone_id == null)
    )

    error_message = "Set both values or neither."
  }
}

variable "hosted_zone_id" {
  description = "Optional Route53 hosted zone ID"
  type        = string
  default     = null
}

# 보안 전용 노드 그룹 생성 여부
variable "enable_security_node_group" {
  type    = bool
  default = false
}

variable "security_node_instance_type" {
  type    = string
  default = "t3.medium"
}

variable "security_node_min_size" {
  type    = number
  default = 1
}

variable "security_node_desired_size" {
  type    = number
  default = 1
}

variable "security_node_max_size" {
  type    = number
  default = 3
}

variable "security_log_retention_days" {
  type    = number
  default = 7
}

variable "cilium_chart_version" {
  description = "Cilium Helm Chart version"
  type        = string
  default     = "1.20.5"
}

variable "tetragon_chart_version" {
  description = "Tetragon Helm Chart version"
  type        = string
  default     = "1.8.0"
}

variable "argocd_chart_version" {
  description = "Argo CD Helm Chart version"
  type        = string
  default     = "10.2.3"
}



