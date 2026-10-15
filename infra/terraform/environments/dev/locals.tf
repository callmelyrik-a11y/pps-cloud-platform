locals {
  name         = "${var.project}-${var.environment}"
  cluster_name = "${local.name}-eks"

  # Exact draw.io subnet layout: 2 AZ x Public / App / DB.
  subnets = {
    public_a = { az = var.availability_zones[0], cidr = cidrsubnet(var.vpc_cidr, 8, 1), tier = "public", az_index = 0 }
    public_b = { az = var.availability_zones[1], cidr = cidrsubnet(var.vpc_cidr, 8, 2), tier = "public", az_index = 1 }
    app_a    = { az = var.availability_zones[0], cidr = cidrsubnet(var.vpc_cidr, 8, 11), tier = "app", az_index = 0 }
    app_b    = { az = var.availability_zones[1], cidr = cidrsubnet(var.vpc_cidr, 8, 12), tier = "app", az_index = 1 }
    db_a     = { az = var.availability_zones[0], cidr = cidrsubnet(var.vpc_cidr, 8, 21), tier = "db", az_index = 0 }
    db_b     = { az = var.availability_zones[1], cidr = cidrsubnet(var.vpc_cidr, 8, 22), tier = "db", az_index = 1 }
  }
}

locals {
  custom_domain_enabled = var.public_domain_name != null && var.hosted_zone_id != null
}
