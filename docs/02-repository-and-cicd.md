# 저장소 운영 및 CI/CD

## 브랜치 · 권한

- `main`: 보호된 기준 브랜치, 직접 Push 제한, PR 최소 1명 승인 권장
- `feature/<issue>-<topic>`: 기능 작업. `fix/<issue>-<topic>`: 결함 수정
- `CODEOWNERS`: 현재 리포지토리 소유자만 지정. 다른 4명의 GitHub 아이디 추가 필요
- `.github/pull_request_template.md`: 변경 영향, 테스트, 보안, 비용 검토
- GitHub Settings → Branch protection / Rulesets: PR 필수, CI 검사 통과, 대화 해결, force-push 제한
- GitHub Environment `pps-dev`: 승인자 및 main 배포 분기 제한. **사용 계정/저장소 요금제에 따라 required reviewers 기능이 제한될 수 있으므로 별도 확인**

## Workflow

| Workflow | Trigger | AWS 인증 | 실제 배포 |
|---|---|---|---|
| `infra-ci.yml` | PR / main Push | 없음 | 없음 (fmt/init -backend=false/validate) |
| `app-ci.yml` | PR / main Push | 없음 | 없음 (FastAPI unit test+Docker build, React build) |
| `infra-deploy.yml` | 수동 plan/apply, main | 기존 OIDC Plan/Apply 역할 | apply 선택 + PPS_APPLY_ENABLED=true + Environment 통과 때만 |
| `app-deploy.yml` | 수동, main | 기존 OIDC Apply 역할 | PPS_APP_DEPLOY_ENABLED=true일 때만 ECR Push/EKS rollout |
| `frontend-deploy.yml` | 수동, main | 기존 OIDC Apply 역할 | PPS_FRONTEND_DEPLOY_ENABLED=true일 때만 S3/CloudFront |

## 필수 GitHub Repository Variables

| 이름 | 값 | 비고 |
|---|---|---|
| `PPS_DEV_FRONTEND_BUCKET_NAME` | `pps-dev-frontend-513329232596-unique` | 실제 사용 가능한 버킷 이름 사용 |
| `PPS_DEV_CLUSTER_PUBLIC_ACCESS_CIDRS` | `["203.0.113.4/32"]` | JSON list. 자신의 실제 공인IP/32로 변경; 예시는 문서용 |
| `PPS_APPLY_ENABLED` | `false` → 승인 후 `true` | Terraform 배포 안전 스위치 |
| `PPS_APP_DEPLOY_ENABLED` | `false` → 준비 후 `true` | EKS/ECR/ServiceAccount 권한 확인 |
| `PPS_FRONTEND_DEPLOY_ENABLED` | `false` → 준비 후 `true` | S3/CloudFront IAM 권한 확인 |
| `PPS_DEV_CLOUDFRONT_DISTRIBUTION_ID` | Terraform output 값 | 프론트 배포 완료 후 캐시 무효화 |

> GitHub Actions의 `vars`는 빈 문자열로 해석될 수 있음. `infra-deploy.yml`은 버킷명/CIDR이 빠지거나 `0.0.0.0/0`이면 plan을 중단함.

## 필수 사전 조건 (반드시 직접 설정)

1. GitHub 저장소 생성. 기존 GitHub Connector는 현재 read-only이므로 새 저장소 생성/Push 작업을 대신할 수 없음.
2. 기존 두 IAM Role의 OIDC **신뢰 정책에 새 repo subject 추가**: Plan→`repo:callmelyrik-a11y/pps-cloud-platform:ref:refs/heads/main`, Apply→`repo:callmelyrik-a11y/pps-cloud-platform:environment:pps-dev`. 이전 저장소의 subject 유지.
3. AWS IAM Role 권한 검토. Terraform State S3, EKS, Aurora, IAM PassRole/Role, CloudFront, WAF, ECR, CloudWatch, Route 53/ACM 등이 필요한 범위만 허용.
4. Terraform State backend 버킷 `my-terraform-state-202610071118` 소유/접근 및 `pps-dev/terraform.tfstate` 충돌 여부 확인. 버킷 versioning 권장. `use_lockfile=true`이므로 계획 및 적용 역할 모두 `pps-dev/terraform.tfstate.tflock`에 필요한 S3 권한을 가져야 함.
5. 환경 `pps-dev`에 승인자와 main branch 제한(가능한 GitHub 플랜의 경우)을 적용. 플랜에서 승인자를 설정할 수 없다면 `PPS_APPLY_ENABLED` 변수를 비활성 상태로 유지하고 별도 승인 절차 마련.
6. 비용, 서비스 버전 지원, 계정 Quota 확인 후 Plan 검토. 배포를 전혀 실행하지 않아도 GitHub Actions 일부 사용량이 발생할 수 있음.

## 적용 순서

1. 코드 PR → Infra CI / App CI 통과
2. PR Merge → `main` 소스 반영 (Apply **안 됨**)
3. `Actions → Infra CD - PPS Dev Plan / Apply → Run workflow → operation: plan`으로 Plan 검토
4. OIDC/권한/S3/버전/비용 점검과 리뷰 후 `PPS_APPLY_ENABLED=true` 및 Environment 보호 활성화
5. 수동 `operation: apply` → 저장된 Plan artifact를 승인된 Job이 그대로 적용. 하나의 Run에서만 Artifacts 소비, 1일 보존
6. 이후 ALB Controller, Cluster Autoscaler, Metrics Server 설치 및 EKS 권한 점검
7. ECR 및 EKS 준비 후 수동 App CD, 프론트 S3/CloudFront 준비 후 Frontend CD

### 주의

- **기존 AWS 접속용 정적 키를 추가하지 않는다.** GitHub OIDC Role Assume을 활용한다.
- `terraform init -backend=false`는 검증용이고 AWS State 접근이 없다.
- PR 코드에서 바로 OIDC write 역할을 호출하지 않는다. AWS Plan은 수동 main 트리거에서만 수행한다.
- `tfplan` 아티팩트에는 비밀 값이 포함될 수 있으므로 다른 곳으로 재배포하지 말고 빠르게 만료시킨다.
- Terraform 프로바이더 lock file은 네트워크 연결된 PC에서 `terraform init` 완료 후 Git에 커밋하기를 권장한다.
