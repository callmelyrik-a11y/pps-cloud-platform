# PPS Cloud Platform

**조달 플랫폼 AWS 마이그레이션 및 DevOps 실습을 위한 5인 팀 모노레포**

> 실제 조달청/나라장터 운영 시스템이 아닌 교육/PoC용 notice/                  # FastAPI + tests + Dockerfile
docs/                                  


팀 개발 및 Git 협업 가이드

PPS Cloud Platform — 5인 팀 협업 규칙

이 문서는 프로젝트 최초 참여부터 Git Clone, 브랜치 생성, 코드 작성, Commit, Push, Pull Request, 코드 리뷰, Merge 및 CI/CD까지의 표준 작업 절차를 정의합니다.

핵심 원칙: 팀원은 개인 작업 브랜치에서 개발하고, Pull Request를 통해 main에 병합합니다. AWS 인프라 및 애플리케이션 배포는 별도의 승인 절차에 따라 수행합니다.

⸻

1. 저장소 정보

항목	내용
프로젝트	PPS Cloud Platform
저장소	callmelyrik-a11y/pps-cloud-platform
기본 브랜치	main
협업 방식	Feature Branch + Pull Request
클라우드	AWS (ap-northeast-2)
IaC	Terraform
컨테이너	Docker / Amazon EKS
백엔드	FastAPI
프런트엔드	React + TypeScript + Vite
자동화	GitHub Actions
AWS 인증	GitHub OIDC 기반 IAM Role

저장소 주소:

https://github.com/callmelyrik-a11y/pps-cloud-platform

2. 프로젝트 최초 참여 방법

STEP 1. GitHub 저장소 접근 권한 확인

프로젝트 관리자가 팀원들을 GitHub 저장소 Collaborator로 초대합니다.

각 팀원은 GitHub에서 초대를 수락해야 원격 저장소의 브랜치에 Push할 수 있습니다.

공개 저장소는 누구나 Clone할 수 있지만, Push 및 PR 작업 권한은 별도입니다.

STEP 2. 필수 프로그램 설치

프로그램	사용 목적	설치 대상
Git	형상 관리	전원
VS Code / IDE	코드 편집	전원
Python 3.12	FastAPI 개발	백엔드
Node.js 22	React 빌드	프런트엔드
Docker	컨테이너 이미지 빌드	앱·플랫폼
Terraform 1.10.5	IaC 검사·관리	인프라
AWS CLI	AWS 리소스 확인	권한이 있는 담당자
kubectl	EKS 리소스 확인	플랫폼 담당자

처음 Clone하고 문서만 수정할 때는 Git만 설치되어 있어도 됩니다.

STEP 3. Git 사용자 정보 설정

최초 1회 실행합니다.

git config --global user.name "본인 GitHub 이름"
git config --global user.email "본인 GitHub 이메일"

현재 설정 확인:

git config --global --list

Commit 작성자 정보는 팀원의 실제 GitHub 계정과 일치하도록 설정합니다.

STEP 4. 저장소 Clone

터미널에서 프로젝트를 저장할 폴더로 이동합니다.

git clone https://github.com/callmelyrik-a11y/pps-cloud-platform.git

Clone한 폴더로 이동합니다.

cd pps-cloud-platform

정상적으로 연결되었는지 확인합니다.

git remote -v
git branch -a
git status

원격 저장소 확인 결과는 다음과 비슷해야 합니다.

origin  https://github.com/callmelyrik-a11y/pps-cloud-platform.git (fetch)
origin  https://github.com/callmelyrik-a11y/pps-cloud-platform.git (push)

주의: 팀원은 새로운 GitHub 저장소를 만들 필요가 없습니다. 모든 팀원은 동일한 원격 저장소를 Clone하여 작업합니다.

⸻

3. Git 브랜치 운영 규칙

브랜치 종류

브랜치	용도
main	통합 기준 코드
feature/*	신규 기능 개발
fix/*	버그 수정
docs/*	문서 작성 및 수정
refactor/*	기능 변경 없는 코드 개선
chore/*	환경설정·유지보수 작업

브랜치 생성 예시:

feature/organization-crud
feature/notice-api
feature/frontend-notice-list
feature/eks-deployment
feature/terraform-network
fix/notice-validation
docs/api-specification
chore/github-actions

브랜치 관리 원칙

* main에는 직접 Push하지 않습니다.
* 모든 개발 작업은 개인 브랜치에서 수행합니다.
* 브랜치는 작업 목적을 식별할 수 있는 이름으로 생성합니다.
* 하나의 브랜치는 가능한 한 하나의 기능 또는 작업 범위만 담당합니다.
* 작업 완료 후 Pull Request를 통해 main에 병합합니다.
* 여러 팀원이 같은 기능을 개발할 때는 사전에 변경할 파일과 담당 범위를 협의합니다.

브랜치 보호 규칙은 README 작성만으로 적용되지 않습니다. 저장소 관리자는 GitHub Settings의 Rulesets 또는 Branch protection을 별도로 구성해야 합니다.

⸻

4. 신규 작업 시작 순서

중요: 새로운 기능을 개발하기 전에는 최신 main을 먼저 받아야 합니다.

STEP 1. main 브랜치로 이동

git switch main

STEP 2. 원격 main 최신 상태 반영

git pull --ff-only origin main

--ff-only는 예상하지 못한 자동 Merge Commit이 발생하지 않도록 제한합니다.

STEP 3. 개인 작업 브랜치 생성

git switch -c feature/notice-api

현재 브랜치 확인:

git branch --show-current

예상 결과:

feature/notice-api

이제 해당 브랜치에서 코드를 수정합니다.

⸻

5. 코드 수정 및 Commit

예를 들어 notice-service 담당자는 다음 디렉터리에서 작업합니다.

apps/services/notice/

STEP 1. 변경 파일 확인

git status

STEP 2. 변경 내용 확인

git diff

STEP 3. 필요한 파일만 Stage

git add apps/services/notice/

Stage에 올라간 파일 확인:

git diff --cached

git add .를 무조건 사용하기보다 변경 파일을 확인하고 필요한 파일만 추가하는 것을 권장합니다.

STEP 4. Commit 작성

git commit -m "feat(notice): add notice creation API"

권장 Commit 형식:

type(scope): description

Type	의미	예시
feat	신규 기능	feat(notice): add notice API
fix	오류 수정	fix(eks): correct ingress path
docs	문서 수정	docs: update API specification
refactor	코드 개선	refactor(organization): simplify service
test	테스트	test(notice): add status tests
chore	기타 관리	chore(ci): update Python version
infra	인프라 변경	infra(vpc): add private routes

Commit은 가능한 한 하나의 논리적인 작업 단위로 작성합니다.

⸻

6. 원격 저장소에 Push

최초 Push:

git push -u origin feature/notice-api

이 명령은 다음 작업을 수행합니다.

1. 로컬 feature/notice-api 브랜치의 Commit을 원격으로 전송합니다.
2. GitHub 원격 저장소에 같은 이름의 브랜치를 생성합니다.
3. 이후 git push, git pull에 사용할 Upstream을 설정합니다.

이후 동일한 브랜치에서 작업할 때는 다음과 같이 사용할 수 있습니다.

git push

중요: Feature Branch에 Push했다고 해서 main에 코드가 병합되는 것은 아닙니다.

로컬 Feature Branch
       │
       │ git push
       ▼
원격 Feature Branch
       │
       │ Pull Request
       ▼
main 브랜치

⸻

7. Pull Request 생성 및 리뷰

Feature Branch를 Push한 뒤 GitHub 저장소에 접속합니다.

1. GitHub의 Compare & pull request 선택
2. Base Branch를 main으로 설정
3. Compare Branch를 본인 Feature Branch로 설정
4. 변경 사항과 테스트 결과 작성
5. Reviewer 지정
6. Pull Request 생성

PR 제목 예시

[BE] 공고 등록 및 상태 전이 API 구현

PR 본문 템플릿

## 작업 목적
공고 등록 및 상태 전이 API 구현
## 변경 사항
- POST /api/notices 추가
- 공고 상태 변경 로직 구현
- Aurora 데이터 접근 계층 추가
- Pytest 테스트 작성
## 테스트 결과
- [ ] 로컬 테스트 통과
- [ ] GitHub Actions CI 통과
- [ ] API Request/Response 확인
## 영향 범위
- apps/services/notice/
- docs/API 문서
## 인프라 및 비용 영향
- AWS 신규 리소스: 없음
- Terraform 변경: 없음
## 리뷰 요청 사항
- API 응답 구조
- 예외 처리
- DB 트랜잭션 처리

PR 승인 및 병합

팀 운영 권장 규칙:

* 본인이 작성한 PR은 다른 팀원이 리뷰합니다.
* 최소 1명의 승인 후 병합합니다.
* 관련 CI가 실행되었다면 반드시 통과 여부를 확인합니다.
* 리뷰에서 요청한 수정 사항을 반영합니다.
* main으로 병합할 때는 가능하면 Squash and merge를 사용합니다.

PR에 추가 Commit을 Push하면 같은 PR에 변경 내용이 자동으로 반영됩니다. 리뷰 중이라는 이유로 새 PR을 다시 만들 필요는 없습니다.

⸻

8. 다른 팀원의 변경 사항 반영

프로젝트를 진행하는 동안 다른 팀원의 PR이 먼저 main에 병합될 수 있습니다.

현재 Feature Branch에 최신 main을 반영하려면 다음 순서로 진행합니다.

git status
git fetch origin
git merge origin/main

충돌이 없다면 자동으로 병합됩니다.

Merge Conflict 발생 시

Git이 표시한 충돌 파일을 열어 변경 내용을 직접 정리합니다.

수정 후:

git add <충돌을_해결한_파일>
git commit
git push

기존 브랜치의 변경 이력을 확인하지 않고 덮어쓰거나 강제로 Push하지 않습니다.

공유 작업 중인 브랜치에서 Rebase 또는 Force Push를 사용하려면 먼저 팀원과 협의해야 합니다.

⸻

9. PR 병합 이후 작업

PR이 main으로 병합되었다면 로컬 개발 환경을 갱신합니다.

git switch main
git pull --ff-only origin main

작업이 끝난 로컬 브랜치는 삭제할 수 있습니다.

git branch -d feature/notice-api

새로운 기능을 개발할 때는 다시 최신 main에서 Feature Branch를 생성합니다.

git switch -c feature/notice-cache

이전 기능 브랜치에서 계속 새로운 기능을 개발하지 않는 것을 원칙으로 합니다.

⸻

10. GitHub Actions CI/CD 운영 방식

이 저장소는 CI와 실제 AWS 배포 CD를 구분합니다.

10.1 PR 및 main Push — 자동 CI

Workflow	트리거	수행 작업
infra-ci.yml	Terraform 관련 PR / main Push	Terraform fmt, init(-backend=false), validate
app-ci.yml	앱 관련 PR / main Push	FastAPI pytest, Docker Build, React Build

GitHub Actions는 관련 경로가 변경될 때 실행되므로 README 등 문서만 변경한 PR에서는 위 검사가 실행되지 않을 수 있습니다.

PR에서 자동 CI를 통과하더라도 AWS 인프라가 생성되거나 EKS에 애플리케이션이 배포되는 것은 아닙니다.

10.2 Terraform Infra CD — 수동 실행

워크플로:

Infra CD - PPS Dev Plan / Apply

GitHub에서 다음 메뉴로 이동합니다.

Actions
 → Infra CD - PPS Dev Plan / Apply
 → Run workflow

현재 설정의 주요 입력값:

operation: plan / apply
dry_run: true / false

권장 실행 순서:

1. main에 검증된 Terraform 코드 병합
2. 수동으로 operation=plan 실행
3. Terraform Plan 결과와 예상 비용 확인
4. 실제 배포가 필요하면 operation=apply 실행
5. Environment 승인 조건 확인
6. 실제 적용을 승인한 경우에만 dry_run=false 사용
7. Apply 후 AWS 리소스 및 Terraform State 확인

현재 워크플로는 dry_run=true가 기본값입니다.

실제 Terraform Apply는 operation=apply, dry_run=false, PPS_APPLY_ENABLED=true 및 Environment 조건을 충족할 때만 실행하도록 작성되어 있습니다.

Environment의 승인자는 GitHub 설정에서 실제로 구성되어 있어야 하며, 승인 보호가 설정되지 않은 경우 자동으로 수동 승인 단계가 생기지 않습니다.

10.3 App CD — ECR / EKS 수동 배포

워크플로:

App CD - FastAPI to EKS

배포 경로:

GitHub Actions 수동 실행(main)
        ↓
AWS OIDC 인증
        ↓
Docker 이미지 빌드
        ↓
Amazon ECR Push
        ↓
kubectl로 Deployment 적용
        ↓
EKS Worker Node 이미지 Pull
        ↓
Pod Rolling Update
        ↓
Rollout Status 확인

실행 조건:

PPS_APP_DEPLOY_ENABLED=true

현재 앱 CD는 organization과 notice 두 서비스의 이미지를 빌드하고 배포합니다.

ECR과 EKS가 미리 준비되어 있어야 하며, AWS IAM 권한 외에 EKS Kubernetes API 접근 권한도 필요합니다.

코드를 GitHub에 Push한 것만으로 ECR Push나 EKS 배포가 자동 실행되는 구조는 아닙니다.

10.4 Frontend CD — S3 / CloudFront 수동 배포

워크플로:

Frontend CD - React to S3 / CloudFront

배포 경로:

React Source
    ↓
npm install / npm run build
    ↓
dist/ 생성
    ↓
AWS OIDC 인증
    ↓
S3 Sync
    ↓
CloudFront Invalidation (설정된 경우)

실행 조건:

PPS_FRONTEND_DEPLOY_ENABLED=true

주의: 프런트 배포에는 aws s3 sync --delete가 사용됩니다. 로컬 빌드 결과에 없는 대상 버킷 객체가 삭제될 수 있으므로, 대상 버킷을 반드시 확인해야 합니다.

⸻

11. GitHub Variables / Secrets 관리

GitHub 저장소의 다음 메뉴에서 관리합니다.

Settings
 → Secrets and variables
 → Actions

Repository Variables

변수	용도
AWS_TERRAFORM_PLAN_ROLE_ARN	Terraform Plan용 IAM Role ARN
AWS_TERRAFORM_APPLY_ROLE_ARN	Terraform Apply용 IAM Role ARN
PPS_DEV_FRONTEND_BUCKET_NAME	프런트엔드 S3 버킷
PPS_DEV_CLUSTER_PUBLIC_ACCESS_CIDRS	EKS API 접근 허용 CIDR
PPS_APPLY_ENABLED	실제 인프라 Apply 활성화
PPS_APP_DEPLOY_ENABLED	앱 CD 활성화
PPS_FRONTEND_DEPLOY_ENABLED	프런트 CD 활성화
PPS_DEV_CLOUDFRONT_DISTRIBUTION_ID	CloudFront 배포 ID
TF_VERSION	Terraform 버전 설정

Repository Secrets

항목	용도
DISCORD_WEBHOOK_URL	Terraform 실행 결과 알림

IAM Role ARN이나 버킷명은 일반적으로 Secret이 아니지만, 비밀번호, 액세스 키, Webhook Token 등의 민감정보는 공개 저장소와 코드에 넣어서는 안 됩니다.

GitHub Actions AWS 인증에는 OIDC를 사용하고, 장기 AWS Access Key를 새로 발급해 저장하는 방식을 지양합니다.

민감한 Terraform 값은 tfplan과 State에 포함될 수 있으므로 해당 산출물의 접근·보관에도 주의합니다.

⸻

12. 로컬 테스트 방법

FastAPI organization-service

프로젝트 최상위 폴더에서:

cd apps/services/organization
python -m pip install -r requirements.txt -r requirements-dev.txt
python -m pytest -q

FastAPI notice-service

프로젝트 최상위 폴더에서:

cd apps/services/notice
python -m pip install -r requirements.txt -r requirements-dev.txt
python -m pytest -q

React 프런트엔드

cd apps/frontend
npm install
npm run build

Terraform 로컬 검증

cd infra/terraform/environments/dev
terraform fmt -check -recursive
terraform init -backend=false
terraform validate

terraform init -backend=false는 원격 State Backend를 사용하지 않고 구성 검증을 준비하기 위한 옵션입니다.

로컬에서 검증 작업을 수행하더라도 AWS에 리소스를 배포하는 terraform apply는 자동 실행되지 않습니다.

실제 DB CRUD 및 업무 API 구현은 추가 개발 대상입니다. 현재 포함된 FastAPI 테스트가 통과한다고 해서 Aurora 통합 기능까지 검증되었다는 뜻은 아닙니다.

⸻

13. 팀원별 작업 담당 범위

프로젝트 시작 시 아래처럼 담당 디렉터리를 지정하는 것을 권장합니다.

담당	주요 작업	디렉터리
A · Infra	VPC, Subnet, Aurora, Terraform	infra/terraform/
B · Platform	EKS, Deployment, ECR, CI/CD	infra/kubernetes/, .github/
C · Backend	organization API 및 DB	apps/services/organization/
D · Backend	notice API, Redis, S3	apps/services/notice/
E · Frontend	React, API 연동	apps/frontend/

디렉터리는 작업 책임의 기준이지 절대적인 편집 제한은 아닙니다.

공통 인터페이스, DB 스키마, GitHub Actions, Terraform State와 같이 다른 팀원에게 영향을 주는 변경은 PR에서 관련 담당자와 함께 검토합니다.

공통 변경이 필요한 경우

예를 들어 Backend 담당자가 Terraform에서 Aurora 설정 변경이 필요하다고 판단했을 때는 다음 순서로 진행합니다.

1. GitHub Issue에 변경 요청 기록
2. Infra 담당자에게 영향 범위 전달
3. Infra 담당자 또는 협업 브랜치에서 Terraform 수정
4. Infra CI 통과 및 Plan 검토
5. PR 리뷰 후 병합
6. 승인된 별도 Infra CD에서 실제 적용

⸻

14. 절대 주의해야 할 사항

Git 관련

* git push origin main을 통한 직접 변경 금지
* git push --force는 공유 브랜치에서 사용 금지
* 다른 사람의 작업을 임의로 삭제·덮어쓰기 금지
* 변경 파일 확인 없이 대규모 git add . 수행 지양
* 임의로 Git History 재작성 금지
* PR 없이 공통 인프라 코드를 변경하지 않기

Terraform 관련

* 승인 없는 terraform apply, terraform destroy 실행 금지
* 기존 Terraform State 임의 삭제 금지
* 기존 실습 State와 PPS 프로젝트 State 혼용 금지
* State 파일을 수동 수정하거나 Git에 커밋하지 않기
* Terraform Lock을 이유 없이 강제 해제하지 않기
* Plan 결과에서 리소스 삭제·교체·비용 증가 여부 반드시 확인

AWS 비용 관련

* EKS, NAT Gateway, Aurora, ALB 등은 실행 중 비용 발생 가능
* 테스트 종료 후 사용하지 않는 리소스 확인
* 신규 AWS 리소스 추가 시 담당자와 비용 검토
* 서비스 삭제 시 데이터·State·의존 관계 확인

보안 관련

다음 파일과 정보를 GitHub에 업로드하지 않습니다.

.env
.env.local
*.pem
*.key
terraform.tfvars
*.tfstate
*.tfplan
AWS Access Key
DB Password
API Token
Webhook Secret

.gitignore로 제외되더라도 이미 추적 중인 파일은 별도로 관리해야 합니다.

실수로 인증정보를 Commit했다면 파일 삭제만으로 해결되지 않습니다. 관련 자격 증명 폐기·재발급과 Git 기록 및 접근 범위를 점검해야 합니다.

⸻

15. 자주 발생하는 Git 오류

15.1 Push rejected — fetch first

! [rejected] main -> main (fetch first)

원격 브랜치에 로컬에 없는 Commit이 존재할 때 발생할 수 있습니다.

main에서 작업 중이라면 우선:

git switch main
git pull --ff-only origin main

단, 로컬 미반영 변경이 있다면 먼저 Commit 또는 Stash로 보관해야 합니다.

개인 Feature Branch가 뒤처진 경우에는 git fetch 후 충돌을 해결해 통합합니다. 다른 사람의 Commit을 강제 덮어쓰지 않습니다.

15.2 Authentication failed / HTTP 403

remote: Permission denied
fatal: unable to access repository

확인 항목:

1. GitHub 로그인 계정이 올바른지 확인
2. 저장소 Collaborator 권한 확인
3. 초대 수락 여부 확인
4. Git Credential Manager 또는 GitHub CLI 인증 상태 확인

15.3 pathspec 오류

error: pathspec '파일명' did not match any file(s)

현재 작업 위치나 브랜치, 실제 파일 경로가 다를 수 있습니다.

git status
git branch --show-current
git ls-files

15.4 Merge Conflict

충돌 표시:

<<<<<<< HEAD
내 작업
=======
다른 브랜치 작업
>>>>>>> ...

두 코드 중 필요한 내용을 정리한 다음 충돌 마커를 제거하고 저장합니다.

git add <충돌_해결_파일>
git commit

충돌 원인이 불분명하다면 임의로 한쪽 내용을 삭제하지 말고 해당 파일 담당자에게 확인합니다.

15.5 잘못된 원격 주소

git remote -v

기존에 잘못된 저장소를 가리키는 경우:

git remote set-url origin https://github.com/callmelyrik-a11y/pps-cloud-platform.git

정상 Clone했다면 이 명령을 다시 실행할 필요는 없습니다.

⸻

16. 신규 팀원 작업 체크리스트

* [ ]	GitHub 저장소 초대 수락
* [ ]	Git 설치 및 사용자 정보 설정
* [ ]	저장소 Clone 완료
* [ ]	origin 원격 주소 확인
* [ ]	main 최신 상태 반영
* [ ]	개인 Feature Branch 생성
* [ ]	담당 디렉터리 및 개발 범위 확인
* [ ]	코드 수정 및 로컬 테스트
* [ ]	변경 파일 확인 후 Commit
* [ ]	개인 Feature Branch Push
* [ ]	Pull Request 작성
* [ ]	GitHub Actions 검사 확인
* [ ]	Reviewer 승인
* [ ]	main Merge
* [ ]	필요한 경우 담당자의 배포 승인 요청

⸻

17. 표준 작업 흐름 최종 요약

1. git clone
        ↓
2. git switch main
        ↓
3. git pull --ff-only origin main
        ↓
4. git switch -c feature/my-task
        ↓
5. 소스 코드 작성 및 테스트
        ↓
6. git add / git commit
        ↓
7. git push -u origin feature/my-task
        ↓
8. GitHub Pull Request
        ↓
9. 관련 CI 실행 및 리뷰
        ↓
10. main Merge
        ↓
11. Infra / App / Frontend CD 필요 여부 판단
        ↓
12. 담당자의 수동 배포 및 승인
        ↓
13. 배포 결과·로그·기능 검증

프로젝트 운영 원칙

개발자는 개인 브랜치에서 기능을 개발하고, Pull Request를 통해 변경 내용을 공유한다. 모든 변경은 코드 리뷰 및 관련 자동 검증을 거쳐 main에 병합하며, AWS 인프라 및 애플리케이션의 실제 배포는 별도 권한과 승인 절차에 따라 수행한다.

이를 통해 5명의 팀원이 하나의 저장소에서 병렬 작업하면서도 코드 품질, 인프라 일관성, 변경 이력 및 배포 안정성을 유지한다.

⸻

