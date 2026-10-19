[README.md](https://github.com/user-attachments/files/33653331/README.md)
# PPS Cloud Platform

조달청형 모의 입찰 서비스를 AWS에 구축하는 학습·팀 프로젝트입니다. 기관의 공고 등록부터 기업의 공고 조회·입찰, 개찰·낙찰까지의 흐름을 단순화해 구현합니다.

저장소: https://github.com/callmelyrik-a11y/pps-cloud-platform

## 프로젝트 구성 방향

| 영역 | 구성 방향 |
| --- | --- |
| 프런트엔드 | React 정적 파일, S3, CloudFront |
| 백엔드 | FastAPI, EKS 기반 배포 |
| 데이터베이스 | Aurora MySQL |
| 캐시 | Redis |
| 네트워크 | 2개 AZ, Public / Private App / Private DB 서브넷 |
| 인프라 관리 | Terraform |
| 자동화 | GitHub Actions, AWS OIDC 역할 |

위 표는 프로젝트 설계 방향입니다. 실제 생성 대상과 배포 조건은 현재 Terraform 코드와 `.github/workflows/`를 기준으로 확인하세요. ECS 포함 여부도 실제 코드에서 확인합니다.

![PPS CI/CD 아키텍처](https://pps-pipeline-diagram.tonynala97.chatgpt.site/pipeline.png)

## 1. 참여 전 준비

1. GitHub 계정을 준비하고 저장소 관리자에게 협업자 초대를 요청합니다.
2. 초대를 수락합니다. 직접 쓰기 권한이 없다면 Fork 후 PR을 제출합니다.
3. Git과 편집기를 설치합니다.
4. 인프라 작업자는 AWS CLI와 Terraform을 설치합니다. Terraform 버전은 코드의 `required_version`, Provider 버전은 `.terraform.lock.hcl`을 따릅니다.
5. 작업할 Issue와 담당 파일 범위를 팀원들과 정합니다.

GitHub 저장소 권한과 AWS IAM 권한은 별개입니다. GitHub에 참여하기 위해 AWS 액세스 키를 공유할 필요는 없습니다.

## 2. 저장소 복제와 Git 사용자 설정

```bash
git clone https://github.com/callmelyrik-a11y/pps-cloud-platform.git
cd pps-cloud-platform

git config user.name "본인 이름"
git config user.email "본인 GitHub 이메일 또는 GitHub 비공개 이메일"

git remote -v
git status
```

`user.name`과 `user.email`은 커밋 작성자 정보이며 로그인 정보가 아닙니다. HTTPS push 인증은 Git Credential Manager 등 GitHub 인증 방식을 사용합니다. 비밀번호나 토큰을 원격 URL에 넣지 마세요.

## 3. 브랜치에서 작업하기

새 작업을 시작할 때, 미커밋 변경이 없는 상태에서 실행합니다.

```bash
git switch main
git pull --ff-only origin main
git switch -c feature/notices-api
```

| 작업 | 브랜치 예시 |
| --- | --- |
| 프런트엔드 | `feature/frontend-notices` |
| 백엔드 | `feature/notices-api` |
| 네트워크 | `infra/network-subnets` |
| 배포 자동화 | `ci/terraform-validation` |
| 문서 | `docs/contribution-guide` |
| 오류 수정 | `fix/notice-validation` |

브랜치 이름은 작업별로 구분합니다. 팀 운영 원칙은 main 직접 push 대신 PR을 사용하는 것입니다. 실제 강제 여부는 저장소의 브랜치 보호 설정에 따릅니다.

## 4. 담당 파일만 커밋하기

먼저 변경 사항을 확인합니다.

```bash
git status
git diff
```

아래는 README만 커밋하는 예시입니다. 다른 파일은 실제 담당 경로로 바꿔 지정하세요.

```bash
git add README.md
git diff --cached --name-only
git diff --cached
git commit -m "docs: 기여자 참여 안내 추가"
git push -u origin feature/notices-api
```

`git add .`는 현재 경로의 다른 변경도 포함할 수 있으므로 파일을 확인하고 사용합니다. 커밋은 지정한 파일만이 아니라 이미 스테이징된 모든 변경을 포함하므로 반드시 `git diff --cached`를 확인합니다.

잘못 스테이징한 파일은 다음처럼 제외합니다. 수정 내용은 유지됩니다.

```bash
git restore --staged README.md
```

같은 파일에서 일부 수정만 포함하려면 다음 명령을 사용합니다.

```bash
git add -p README.md
```

`push`는 파일을 선택하는 작업이 아니라 브랜치의 커밋을 전송하는 작업입니다. 파일 선택은 `add`와 `commit` 단계에서 합니다.

## 5. Pull Request 제출

1. GitHub에서 자신의 브랜치를 선택하고 **Compare & pull request**를 누릅니다.
2. base를 `main`, compare를 자신의 작업 브랜치로 지정합니다.
3. **Files changed**에서 담당하지 않은 파일과 비밀정보가 없는지 확인합니다.
4. 변경 목적, 동작 변화, 확인 방법, 인프라 영향 등을 작성합니다.
5. 리뷰를 요청하고 현재 PR에 실행되는 CI 결과를 확인합니다.
6. 수정이 필요하면 같은 브랜치에 추가 커밋·push합니다. PR에 반영됩니다.
7. 리뷰와 필요한 검증을 통과한 후 병합 담당자가 main에 병합합니다.

PR 본문 예시:

```markdown
## 변경 내용
- 공고 목록 조회 기능 추가

## 확인 방법
- 실행한 명령과 결과
- 필요한 경우 화면 또는 API 응답 예시

## 영향
- API / DB / Terraform 변경 여부
- 인프라 생성·삭제·교체 여부

관련 Issue: #번호
```

## 6. 최신 main 반영과 충돌 해결

작업 내용을 먼저 커밋한 후 자신의 브랜치에서 실행합니다.

```bash
git fetch origin
git merge origin/main
```

충돌이 생기면:

1. `git status`로 충돌 파일을 확인합니다.
2. 파일의 충돌 표시를 정리하고 양쪽 변경 의도를 반영합니다. 다른 팀원의 코드를 무조건 덮어쓰지 않습니다.
3. 해결한 파일만 `git add`합니다.
4. `git commit`으로 병합을 완료하고 `git push`합니다.

병합을 취소하려면 `git merge --abort`를 사용합니다. 미커밋 변경이 있다면 병합 전에 별도로 보존하세요. 공동 브랜치에서 임의의 force push나 `reset --hard`를 사용하지 않습니다.

병합된 작업 이후 새 작업은 최신 main에서 새 브랜치로 시작합니다.

## 7. Terraform 실행 전: AWS 계정과 state 구분

| 실행 환경 | 의미 | state 원칙 |
| --- | --- | --- |
| 프로젝트 계정의 IAM 사용자 | 같은 AWS 계정에서 공동 리소스 관리 | 동일 리소스에는 동일 원격 state 사용 |
| 팀원 개인 AWS 계정 | 각자 별도 리소스와 비용 발생 | 개인 backend 또는 개인 로컬 state 사용 |

IAM 사용자 이름이 다르더라도 `Account`가 같으면 같은 AWS 계정입니다. 실행 전에 확인합니다.

```bash
aws sts get-caller-identity
```

코드에 고정된 `profile`이나 `assume_role`이 있다면 실제 Provider가 사용하는 계정도 추가로 확인합니다. CLI의 기본 계정만으로 판단하지 않습니다.

### 공동 인프라

- 기존 S3 backend를 임의로 삭제하거나 개인용으로 변경하지 않습니다.
- 같은 리소스를 서로 다른 state에서 중복 관리하지 않습니다.
- 공동 인프라 Apply는 팀에서 지정한 배포 담당자 또는 승인된 파이프라인으로 진행합니다.
- state 잠금을 우회해 동시에 Apply하지 않습니다.

### 개인 계정 실습

- S3 버킷 이름, 고정 계정 ID·IAM Role ARN, 기존 리소스 ID를 개인 환경에 맞춥니다.
- 프로젝트 공동 state를 사용하지 않습니다.
- 도메인이 없다면 해당 코드의 `public_domain_name`, `hosted_zone_id`를 빈 문자열로 설정해 선택 기능을 끕니다.
- 개인 backend로 전환하는 작업은 개인 실습용 복사본에서 진행하며 공동 저장소의 backend 변경을 실수로 커밋하지 않습니다.
- 로컬 state를 사용한다면 `terraform.tfstate`를 안전하게 보관합니다. Git에는 올리지 않습니다.
- EKS·ECS·Aurora는 코드에 포함되어 있다면 생성 대상입니다. 제외 설정이 구현됐는지 확인하지 않고 Apply하지 않습니다.

## 8. Terraform 검증과 배포

현재 환경 경로를 확인한 뒤 실행합니다. 아래 경로는 프로젝트에서 사용하는 dev 환경 경로이며 브랜치에서 구조가 바뀌었다면 해당 경로로 조정합니다.

```bash
cd infra/terraform/environments/dev
terraform fmt -check -recursive
terraform init
terraform validate
terraform plan -out=tfplan
```

Plan에서 생성·변경·삭제 수, 교체 대상, 계정별 이름과 CIDR을 확인합니다. 배포 권한과 담당 범위를 확인한 경우에만 저장한 Plan을 적용합니다.

```bash
terraform apply tfplan
```

Terraform은 실행 폴더의 모든 `.tf` 파일을 하나의 구성으로 읽습니다. 특정 파일만 선택해서 Apply할 수 없습니다. 파일을 지우거나 생성 옵션을 끄면 이미 관리 중인 리소스가 삭제 대상으로 바뀔 수 있습니다. `-target`을 일상적인 담당 범위 분리 수단으로 사용하지 않습니다.

GitHub Actions의 실제 트리거, Plan/Apply 조건, 승인 여부는 `.github/workflows/`와 저장소 Environment 설정에서 확인합니다. PR 병합 자체가 AWS 배포 완료를 의미하지 않습니다. OIDC 역할은 실행 주체용이며 개인 액세스 키를 워크플로 파일에 넣지 않습니다.

## 9. 커밋하지 않는 파일

기존 `.gitignore`를 확인하고 필요한 패턴을 병합합니다.

```gitignore
**/.terraform/*
*.tfstate
*.tfstate.*
*.tfplan
tfplan
crash.log
crash.*.log
.env
.env.*
!.env.example
*.pem
*.key
*.local.tfvars
*.local.tfvars.json
```

- 비밀번호, AWS Secret Access Key, 세션 토큰, DB 접속정보를 커밋하지 않습니다.
- 개인 변수는 예를 들어 `personal.local.tfvars`에 두고 `-var-file=personal.local.tfvars`로 전달합니다. Plan 때 사용한 변수로 저장한 Plan을 Apply합니다.
- `.terraform.lock.hcl`은 버전 재현을 위해 커밋합니다.
- `.gitignore`는 이미 추적 중인 파일을 자동으로 제외하지 않습니다. 자격증명이 이미 노출됐다면 우선 폐기·교체하고 관리자에게 알립니다.

## 10. 팀 협업 원칙

- 작업 시작 전에 Issue에 담당 범위와 예상 변경 파일을 공유합니다.
- 공통 변수, Provider, backend, 워크플로, DB 스키마 변경은 관련 담당자와 먼저 조율합니다.
- 한 PR에는 하나의 목적을 담고 관련 없는 포맷 변경은 섞지 않습니다.
- 코드 변경에 맞는 검증 결과를 PR에 남깁니다. 문서만 바뀐 경우 인프라 Apply는 필요하지 않습니다.
- 비용이 발생하는 리소스의 생성·삭제는 팀 배포 절차에 따릅니다.
- 실제 담당자, 배포 권한, 승인자는 프로젝트 관리자가 정하고 변경 시 공유합니다.

## 자주 발생하는 문제

| 증상 | 확인할 내용 |
| --- | --- |
| `push rejected` / `fetch first` | 원격 변경을 fetch하고 현재 브랜치에 병합한 뒤 다시 push. force push로 덮어쓰지 않음 |
| GitHub 쓰기 권한 오류 | 협업자 초대 수락 여부, 인증된 GitHub 계정 확인 |
| S3 backend `AccessDenied` | backend 버킷·경로와 state 접근 권한 확인 |
| `No state file was found` | 실행 폴더, init 완료 여부, backend와 workspace 확인 |
| 버킷 이름 중복 | 계정 ID 등을 포함한 고유한 버킷 이름 사용 |
| AWS `AccessDenied` | 실제 실행 계정·역할과 필요한 IAM 권한 확인 |
| 담당하지 않은 파일이 PR에 포함됨 | staged 변경과 main 대비 브랜치 diff 확인 후 불필요한 변경 정리 |

