# 기존 IAM OIDC Role의 신뢰 정책 확장

GitHub AWS OIDC Provider: `arn:aws:iam::513329232596:oidc-provider/token.actions.githubusercontent.com`

**중요:** 아래는 추가할 `Statement` 예시이며 기존 실습 저장소 접근 권한은 삭제하지 않는다. Role 자체의 AWS API 권한 정책과는 별개다.

## Plan Role (`GitHubActions-Terraform-Plan-Role`)

현재 `main`에서 실행하는 새 조달청 Plan Job의 OIDC subject는:

```text
repo:callmelyrik-a11y/pps-cloud-platform:ref:refs/heads/main
```

기존 신뢰 정책의 허용 subject 목록에 위 값을 **추가**한다. 추가 Statement 예:

```json
{
  "Effect": "Allow",
  "Principal": { "Federated": "arn:aws:iam::513329232596:oidc-provider/token.actions.githubusercontent.com" },
  "Action": "sts:AssumeRoleWithWebIdentity",
  "Condition": {
    "StringEquals": {
      "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
      "token.actions.githubusercontent.com:sub": "repo:callmelyrik-a11y/pps-cloud-platform:ref:refs/heads/main"
    }
  }
}
```

## Apply Role (`githubactions-terraformrole`)

환경 `pps-dev` 사용 시 새로운 OIDC subject:

```text
repo:callmelyrik-a11y/pps-cloud-platform:environment:pps-dev
```

`Condition.StringEquals`의 `sub`만 위 subject로 치환한 Allow Statement를 기존 Role의 신뢰 정책에 추가한다. 환경 승인/branch restriction이 반드시 필요하다. Role을 동일하게 재사용하면 기존 실습과 보안 경계가 약하므로 추후 프로젝트 전용 IAM Role 분리 권장.

## 검증

- 새 repo 생성 → Settings → Secrets and variables → Actions에서 변수 설정
- Settings → Environments → `pps-dev`에서 reviewer/branch restriction 확인
- `Infra CD` 수동 `plan` 실행 → `Configure AWS Credentials` 성공 및 `aws sts get-caller-identity` 확인
- S3 backend Put/Get/tflock 권한 실패 시 IAM 정책 확인
- `apply`는 리뷰, 비용 확인, 승인 보호 활성화 전에는 켜지 않기
