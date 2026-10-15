# PPS 클라우드 아키텍처 (Phase 1)

## 네트워크 및 요청 흐름

- Route 53 (선택) → CloudFront(+WAF, OAC) → Private S3 (React 정적 자산)
- API: 별도 도메인/HTTPS ALB → EKS FastAPI (Organization, Notice) → Aurora MySQL Serverless v2
- ALB: 공용 서브넷 A/B를 아우르는 **하나의 논리적 L7 로드밸런서**, AWS Load Balancer Controller가 Kubernetes Ingress 기반으로 생성 (현재 Helm 설치 미완료)
- EKS: Managed Node Group, 두 프라이빗 애플리케이션 서브넷, HPA 60% CPU 2~10 Pods, CA 2~4 Nodes (애드온 설치 필요)
- Aurora: 한 클러스터, A Writer/B Reader, 공유 클러스터 스토리지, 프라이빗 DB 서브넷
- Internet egress: 애플리케이션 서브넷 A→NAT-A, B→NAT-B; DB 서브넷 기본 인터넷 경로 없음
- Logging/alerts: CloudWatch와 SNS 기본 알람. 애플리케이션 로그 수집은 Fluent Bit/CloudWatch Observability 별도 설치 필요

## CIDR

| 티어 | AZ-A | AZ-B |
|---|---|---|
| Public | 10.20.1.0/24 | 10.20.2.0/24 |
| App | 10.20.11.0/24 | 10.20.12.0/24 |
| DB | 10.20.21.0/24 | 10.20.22.0/24 |

## 범위와 실습 주의

- 현재 Terraform은 ALB/EKS 워크로드 전체가 아니라 **기반 인프라**를 구성
- ECR: 두 개 (organization, notice). 데이터베이스 연동, 인증, 실제 입찰 업무 API는 아직 미구현
- CloudFront는 현재 S3 원본만 제공. API와 통합하는 동작은 HTTPS ALB/도메인 설계 후 수행
- WAF의 CloudFront 보호가 별도 ALB를 자동으로 보호하는 것은 아님
- VMware 전환 효과는 가설로 정리하고 실제 TCO 계산으로 검증해야 함
- 조달청 공식 서비스/운영망 복제가 아닌 교육 목적 프로토타입
