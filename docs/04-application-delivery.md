# 애플리케이션 CI/CD 준비 상태

## 현재 포함된 코드

- React+Vite 기본 랜딩 페이지. **API 연결 및 인증 미구현**
- `organization` / `notice` FastAPI: `/healthz` 및 예시 GET API만 존재. **Aurora CRUD 미구현**
- 두 서비스 Dockerfile, Pytest smoke tests
- K8s Deployment/Service/HPA (namespace `pps-dev`), CI 빌드 검증
- AWS ECR Repository 2개를 Terraform에서 관리

## EKS 실제 배포 선행 조건

1. Terraform Infra Apply: ECR, EKS 클러스터, Node Group, NAT, CloudWatch 등 생성
2. IAM: GitHub Actions Apply Role의 `ecr:PutImage`, `ecr:InitiateLayerUpload`, `ecr:UploadLayerPart`, `ecr:CompleteLayerUpload`, `ecr:GetAuthorizationToken`, `eks:DescribeCluster` 및 Kubernetes API 인증 권한 확인
3. EKS Role의 액세스 엔트리 / cluster access policy 또는 Kubernetes RBAC 권한 부여. IAM Role Assume만으로 kubectl 권한이 생기지는 않음
4. HPA를 위해 Metrics Server 설치; 리소스 사용량 검증
5. API 공인 ALB를 만들려면 AWS Load Balancer Controller Helm+Pod Identity 정책 설치 후 `ingress-example.yaml`의 ACM/TLS와 WAF/SG 설정을 완료. 예시 Ingress를 그대로 운영에 적용하지 말 것
6. Cluster Autoscaler Helm 설치/권한 및 노드 확장 검증
7. CloudWatch 에이전트/Container Insights 별도 구성

## 프론트엔드

- Terraform으로 생성한 S3 버킷에 `npm run build` 결과 업로드.
- CloudFront OAC가 S3 접근을 제어; SPA는 403 fallback `index.html` 설정.
- 프론트와 API는 현재 별도 오리진. 앱 코드 API 통신을 구현할 때 API 도메인 + CORS + 인증을 설계.
- React dependencies lockfile은 아직 없으므로 CI는 `npm install`을 사용. 최초 정상 설치 시 `npm install --package-lock-only`로 `package-lock.json`을 생성/커밋한 후 CI를 `npm ci`로 변경할 것.

> 실제 나라장터 로고/공식 인증 체계를 포함하지 않는 교육용 예제.
