terraform {
  required_version = ">= 1.10.0"

  required_providers {

    # AWS 인프라 리소스 관리
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.63"
    }

    # Kubernetes Helm Chart 관리
    # Cilium, Hubble, Argo CD 설치
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
  }

  # Terraform Remote State
  backend "s3" {
    bucket       = "my-terraform-state-202610071118"
    key          = "pps-dev/terraform.tfstate"
    region       = "ap-northeast-2"
    encrypt      = true
    use_lockfile = true
  }
}

# ============================================================
# 1. AWS Provider - Seoul Region
# ============================================================

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# ============================================================
# 2. AWS Provider - CloudFront / Global WAF
# ============================================================

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

# ============================================================
# 3. Helm Provider - EKS Authentication
# ============================================================

provider "helm" {

  kubernetes = {

    # EKS Kubernetes API Server Endpoint
    host = aws_eks_cluster.g2b_konep_eks.endpoint

    # EKS API Server CA 인증서
    # Base64 데이터를 PEM 인증서로 디코딩
    cluster_ca_certificate = base64decode(
      aws_eks_cluster.g2b_konep_eks.certificate_authority[0].data
    )

    # AWS CLI를 이용하여 EKS 인증 토큰 획득
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"

      args = [
        "eks",
        "get-token",
        "--cluster-name",
        aws_eks_cluster.g2b_konep_eks.name,
        "--region",
        var.region
      ]
    }
  }
}
