# PPS Dev: EKS + Aurora MySQL + CloudFront/S3

This is an **independent Terraform root module** for the procurement-platform project.
The existing repository root is an EC2/ALB/ASG laboratory; do not replace it or reuse its state.

## Phase-1 scope
- VPC 10.20.0.0/16, Seoul region, 2 AZs (`2a`, `2b` by default)
- 2 public subnets / 2 private app subnets / 2 isolated private DB subnets
- IGW; 2 NAT gateways and 2 EIPs; 2 AZ-specific app route tables
- EKS control plane, Managed Node Group (2..4 on-demand `t3.medium`)
- AWS-managed EKS Pod Identity Agent plus default Kubernetes add-ons
- Aurora MySQL Serverless v2 (one writer in AZ-a + one reader in AZ-b)
- Aurora Secrets Manager-managed master password
- Private S3 frontend bucket, CloudFront OAC, CloudFront-scoped WAF
- CloudWatch control-plane logs, Aurora alarms, NAT error alarms, simple dashboard
- Cluster Autoscaler IAM Pod Identity role + ASG discovery tags

Not yet deployed: ALB, Helm controller, Cluster Autoscaler Helm deployment,
Metrics Server, CloudWatch EKS Container Insights. ECR repositories are now defined in ecr.tf;
FastAPI example applications/manifests exist, but have NOT been deployed. Route 53/ACM custom frontend domain is optional (provide both `public_domain_name` and `hosted_zone_id`).
Those need application settings, role policies, domain ownership, Helm setup and/or separate deployment stages.
**SQS/KEDA/async Worker intentionally excluded.**

## Critical safety checks
1. The connected repository has backend bucket `my-terraform-state-202610071118` and root state key `aws-lab/terraform.tfstate`.
   This module uses `pps-dev/terraform.tfstate` instead. **Verify the S3 bucket is owned by the expected AWS account and accessible.**
2. `terraform apply` can incur cost for EKS, EC2 nodes, 2 NAT gateways, Aurora writer + reader,
   CloudFront and WAF. Check credits, account quotas, and estimated costs first.
3. `frontend_bucket_name` must be globally unique. Provide a value through a local untracked `.tfvars` file or `TF_VAR_frontend_bucket_name`.
4. Verify EKS version and Aurora engine version availability in ap-northeast-2 before `apply`.
5. For development, EKS API public access is enabled. Restrict `cluster_public_access_cidrs` to your current source IP when possible.
6. `skip_final_snapshot=true` and `deletion_protection=false` are **learning-only** database defaults. Destruction may permanently delete data.
7. EKS initial `t3.medium` node minimum 2 might be tight for telemetry/controller add-ons; verify allocatable CPU/RAM before installing all add-ons.
8. Private Subnet IP capacity is a constraint when scaling EKS VPC CNI Pods (each App `/24`).
9. Static web does not yet have a real React build. Upload `index.html` and assets to the S3 bucket after creation.
10. WAF rate rules and managed rule groups can block legitimate requests; tune after testing.

## PowerShell commands (local preview)
```powershell
cd infra/terraform/environments/dev
Copy-Item terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars: unique frontend_bucket_name and supported versions.
aws sts get-caller-identity
terraform init
terraform fmt -recursive
terraform validate
terraform plan -out=pps-dev.tfplan
terraform show pps-dev.tfplan
# Only after reviewing the plan and cost:
# terraform apply pps-dev.tfplan
```

Use `terraform init -backend=false` for static validation only; it does not access the current S3 state.
GitHub's existing root workflows intentionally remain untouched. `infra-ci.yml` does not authenticate to AWS or apply infrastructure.
The existing root PR plan may still run and report its own result on repository PRs; it works against the **old lab state**, not this module.

## Layer ordering
1. Network VPC and 6 subnets, route tables, NAT.
2. EKS control plane and Managed Node Group.
3. Aurora Serverless v2 writer and reader; frontend S3/CloudFront; CloudWatch.
4. AWS Load Balancer Controller / Cluster Autoscaler / Metrics Server Helm installation and Pod Identity.
5. Build/push FastAPI container, Deployment + Service + HPA + Ingress.
6. Add CloudWatch Container Insights/Fluent Bit, alerts and ALB metrics after ALB exists.

## AWS Load Balancer Controller step
- Terraform provisions **one ALB Controller Pod Identity role only when** `alb_controller_policy_arn` is set.
- Follow AWS Load Balancer Controller official installation guidance for a policy compatible with your chosen controller release.
- Create the IAM policy, add its ARN to `terraform.tfvars`, `plan`, `apply`, then install the Helm chart with an existing ServiceAccount.
- Use `ingressClassName: alb`, `scheme: internet-facing`, `target-type: ip`.
- **ALB is one logical resource spanning the two public subnets** (not one ALB per AZ).
- The Controller needs to be installed before applying the sample Ingress.
- The YAML example listens on HTTP:80 **for connectivity testing only**; add ACM + HTTPS listener before public use.

## Cluster Autoscaler step
- ASG discovery tags and a `kube-system/cluster-autoscaler` Pod Identity IAM association are in Terraform.
- Install the Cluster Autoscaler chart/version matching the EKS Kubernetes minor version with `rbac.serviceAccount.name=cluster-autoscaler`.
- Install Metrics Server before relying on HPA metrics.
- Do NOT use another node autoscaler on this same node group at the same time.
- HPA min 2/max 10 replicas and CPU target 60% are examples; Pod requests must be realistic.
- EKS Managed Node Groups do not guarantee one running node per AZ. If strict per-AZ node minimums are required, split into one node group per AZ.

## DB routing
- Writer endpoint: `terraform output -raw aurora_writer_endpoint`
- Reader endpoint: `terraform output -raw aurora_reader_endpoint`
- Reader endpoint does not automatically parse SQL. Use separate app connections and send read-after-write or strongly consistent queries to Writer.
- Master secret ARN: `terraform output -raw aurora_master_secret_arn`; give Pods only least-privilege Secrets Manager access.
- Reader failover is managed by Aurora; verify actual roles with DB queries after failover rather than relying on the instance naming.

## Frontend and API URLs
- CloudFront initially serves **S3 only** and provides an AWS-generated `*.cloudfront.net` domain.
- Optional custom frontend domain: set `public_domain_name` and `hosted_zone_id` together; Terraform creates ACM DNS validation (us-east-1) and Route 53 alias. Without them the default CloudFront domain is used.
- API endpoint initially comes from the ALB DNS after Ingress deployment; configure CORS for separate web/api origins.
- Later you can add a `/api/*` CloudFront origin for ALB, but first provision a domain/TLS certificate and set appropriate cookies/auth headers and cache behavior.

## Monitoring
- CloudWatch cluster API/audit logs, Aurora CPU alarms, NAT port allocation alarms and dashboard are in Terraform.
- Application stdout logs are **not automatically ingested** into the pre-created CloudWatch Log Group.
- Install CloudWatch Observability add-on / Container Insights with correct IAM before expecting per-Pod metrics/logs.
- For application logs, configure CloudWatch agent/Fluent Bit and log retention.
- Set `alarm_email` and confirm the SNS subscription to receive alarm notifications.
- ALB alarms need ALB ARN suffix/Target Group identifiers, known only after Controller creates them.

## State and CI/CD follow-up
- Root workflows use `terraform init`, `plan`, `apply`, and `destroy` in the repository root. They are NOT modified here.
- Do not enable a new `pps-dev apply` workflow until AWS OIDC trust policy and approval protection are reviewed.
- For later CI, use `working-directory: environments/pps-dev`, a dedicated GitHub Actions concurrency group, a separate OIDC role or carefully scoped permissions, and the distinct S3 key.

## New monorepo notes
- Infrastructure root was moved to `infra/terraform/environments/dev`; the S3 backend key is unchanged.
- Workflows under `.github/workflows` assume the existing AWS Plan/Apply roles and require the new repository OIDC subjects.
- ECR repositories are provisioned by this Terraform root. The actual ALB is created later by AWS Load Balancer Controller.
- Terraform state remains `s3://my-terraform-state-202610071118/pps-dev/terraform.tfstate`. No state migration is required **if not deployed previously**.
