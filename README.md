# PPS Cloud Platform

**조달 플랫폼 AWS 마이그레이션 및 DevOps 실습을 위한 5인 팀 모노레포**

> 실제 조달청/나라장터 운영 시스템이 아닌 교육/PoC용 아키텍처입니다.

## 범위

- **IaC:** Terraform, ap-northeast-2, VPC 10.20.0.0/16, 2 AZ, Public/App/DB subnet 6개, NAT 2개
- **Container:** EKS Managed Node Group, ECR (Organization / Notice) 2개
- **Database:** Aurora MySQL Serverless v2, writer/reader
- **Frontend:** S3 private + CloudFront OAC + WAF, 선택적 Route 53 / ACM
- **Security:** 기존 GitHub OIDC AWS IAM Roles 재사용, State S3 키 별도 관리
- **Monitoring:** CloudWatch/CloudWatch alarms. Container Insights 수집기는 설치 전
- **Applications:** React 랜딩 페이지, FastAPI Organization / Notice 샘플 Health/API (실제 DB/업무 CRUD는 미구현)

## 디렉터리

```text
.github/workflows/                     # Terraform CI/CD, App CI, 수동 App CD
infra/terraform/environments/dev/      # 독립 Terraform root/state
infra/kubernetes/                      # namespace, Deployments/Services/HPAs
apps/frontend/                          # React + Vite
apps/services/organization/            # FastAPI + tests + Dockerfile
apps/services/notice/                  # FastAPI + tests + Dockerfile
docs/                                  # 설계 및 설정 가이드
```

## 생성 전 확인

1. `docs/02-repository-and-cicd.md`의 Repository Vars / OIDC trust 설정
2. `docs/03-oidc-trust-policy.md`의 기존 IAM Role 신뢰 관계 확장
3. S3 state 버킷 `my-terraform-state-202610071118`, 키 `pps-dev/terraform.tfstate` 접근 확인
4. `PPS_DEV_FRONTEND_BUCKET_NAME`과 실제 `/32` EKS API CIDR 설정
5. Terraform Plan/비용/서비스 버전 검토. 기본 구성은 EKS+NAT+Aurora로 **지속 비용 발생**

## 빠른 로컬 검사

```powershell
cd infra/terraform/environments/dev
terraform fmt -recursive
terraform init -backend=false
terraform validate
```

앱 테스트:

```bash
cd apps/services/organization
python -m pip install -r requirements.txt -r requirements-dev.txt
python -m pytest
```

## 중요한 배포 규칙

- PR Merge는 AWS Apply를 자동 실행하지 않음
- Actions → `Infra CD - PPS Dev Plan / Apply`에서 먼저 **plan** 수동 실행
- `apply`는 별도 Environment `pps-dev` 승인 + Repo Variable `PPS_APPLY_ENABLED=true`일 때만
- 애플리케이션 EKS 배포 / S3 배포는 각각 별도 수동 Workflow와 enable variable 사용
- 기존 Terraform 실습 Repository 및 State 파일은 변경하지 않음

상세: [아키텍처](docs/01-architecture.md) · [GitHub Actions 운영](docs/02-repository-and-cicd.md) · [OIDC 신뢰 정책](docs/03-oidc-trust-policy.md) · [앱 배포](docs/04-application-delivery.md)
