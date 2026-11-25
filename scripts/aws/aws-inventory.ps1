#requires -Version 5.1
[CmdletBinding()]
# 실행 인자: 직접 지정하거나, 생략하면 대화형 입력을 받는다.
# Region: 조회 기준 리전 / Profile: AWS CLI 인증 설정 이름 (계정 ID가 아님)
# AllRegions: 활성화된 전체 리전 조회 / OutputRoot: 보고서 저장 경로
# NonInteractive: CI/CD 등에서 Read-Host 입력을 생략하는 옵션
param(
    [string]$Region,
    [string]$Profile,
    [switch]$AllRegions,
    [string]$OutputRoot,
    [switch]$NonInteractive
)
# PowerShell 오류를 종료 가능한 예외로 처리한다.
$ErrorActionPreference='Stop'
# param 바인딩 이후 스크립트 위치를 결정한다.
# PSScriptRoot는 현재 스크립트가 저장된 디렉터리이다. 현재 작업 디렉터리와 다를 수 있다.
$scriptDir = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($scriptDir)) {
# 자동 변수가 비어 있을 때 실행 파일 경로에서 부모 디렉터리를 구한다.
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
}
if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
    $OutputRoot = Join-Path $scriptDir '../../aws-inventory-reports'
}
# AWS CLI 설치 여부를 확인한다.
Get-Command aws -ErrorAction Stop | Out-Null

# 호출자가 값을 전달하지 않았을 때만 입력을 요청한다.
# 빈 Profile은 AWS CLI의 기본 자격 증명 체인을 사용한다.
# PSBoundParameters는 호출자가 명시적으로 전달한 인자의 이름과 값을 담는 사전이다.
# 입력이 리다이렉션된 환경에서는 대화형 질문을 생략한다.
$interactive = -not $NonInteractive -and -not [Console]::IsInputRedirected
if ($interactive -and -not $PSBoundParameters.ContainsKey('Profile')) {
    Write-Host 'Available AWS profiles:'
    # @()는 결과가 한 개 또는 여러 개여도 배열로 취급하도록 한다.
    $profiles = @(& aws configure list-profiles --no-cli-pager)
    if ($LASTEXITCODE -ne 0) { throw 'Could not list configured profiles.' }
    $profiles | ForEach-Object { Write-Host "  $_" }
    # do-while: 유효한 프로파일 또는 빈 값이 들어올 때까지 반복한다.
    do {
        $Profile = (Read-Host 'AWS Profile name [current/default]').Trim()
        # -ccontains는 대소문자를 구별하여 배열에 해당 값이 있는지 검사한다.
        if (-not $Profile -or $profiles -ccontains $Profile) { break }
        Write-Warning 'Unknown profile. Enter a listed profile name, not an AWS account ID.'
    } while ($true)
}
# 리전 미지정 시 입력을 요청하며 Enter만 누르면 서울 리전을 선택한다.
if ([string]::IsNullOrWhiteSpace($Region)) {
    if ($interactive) {
        $Region = (Read-Host 'AWS Region [ap-northeast-2]').Trim()
    }
    if ([string]::IsNullOrWhiteSpace($Region)) { $Region = 'ap-northeast-2' }
}
if ($interactive -and -not $PSBoundParameters.ContainsKey('AllRegions') -and -not $PSBoundParameters.ContainsKey('Region')) {
    $answer = Read-Host 'Scan all enabled regions? [y/N]'
    $AllRegions = $answer -in @('y','yes')
}

# 모든 AWS CLI 호출에 공통 옵션을 추가한다.
# 배열에 옵션과 값을 각각 넣어 네이티브 명령에 전달한다.
$common=@('--output','json','--no-cli-pager')
if($Profile){$common+=@('--profile',$Profile)}
# AWS CLI의 JSON 응답을 PowerShell 객체로 변환한다.
# stderr를 별도 파일에 저장하여 정상 JSON과 섞이지 않게 한다.
function Invoke-AwsJson {
    param([string[]]$Arguments,[string]$Location)
# 임시 파일에 stderr를 분리하여 stdout JSON 파싱 실패를 방지한다.
    $stderr = [IO.Path]::GetTempFileName()
    try {
        # Windows PowerShell 5.1 can treat native stderr as a PowerShell error.
        # Let the process finish and inspect its actual exit code first.
        $previousPreference = $ErrorActionPreference
        try {
            $ErrorActionPreference = 'Continue'
            # &는 호출 연산자, @Arguments와 @common은 배열 스플래팅이다.
            # 2>는 표준 오류 스트림을 파일로 리다이렉션한다.
            $raw = & aws @Arguments --region $Location @common 2> $stderr
            # LASTEXITCODE: 직전 외부 프로그램의 종료 코드. 0은 성공이다.
            $code = $LASTEXITCODE
        } finally {
            $ErrorActionPreference = $previousPreference
        }
        if ($code -ne 0) {
            throw ("AWS CLI exit code " + $code + ": " + (Get-Content -LiteralPath $stderr -Raw))
        }
        # 여러 줄의 stdout을 합친 뒤 JSON을 PowerShell 객체로 역직렬화한다.
        return (($raw -join [Environment]::NewLine) | ConvertFrom-Json)
    } finally {
        # 성공 여부와 관계없이 임시 오류 파일을 제거한다.
        Remove-Item -LiteralPath $stderr -Force -ErrorAction SilentlyContinue
    }
}
# STS로 실제 호출 계정 및 IAM 주체를 확인한다.
$identity=Invoke-AwsJson @('sts','get-caller-identity') $Region
Write-Host "AWS Account: $($identity.Account) | Region: $Region | Profile: $Profile"
# 실행별 고유 보고서 디렉터리를 생성한다.
# 날짜와 GUID 일부를 조합하여 동일 초에 실행해도 보고서를 구분한다.
$folder=Join-Path $OutputRoot ((Get-Date -Format 'yyyyMMdd-HHmmss')+'-'+[guid]::NewGuid().ToString('N').Substring(0,6))
New-Item -ItemType Directory -Path $folder -Force | Out-Null
# Resolve-Path로 상대 경로를 실제 절대 경로로 변환한다.
$folder=(Resolve-Path $folder).Path
# 상세 리소스 객체를 JSON 파일로 저장한다.
# ConvertTo-Json의 Depth는 중첩 객체를 직렬화하는 최대 깊이이다.
function Save-Json($Value,$Path){ConvertTo-Json -InputObject $Value -Depth 100 | Set-Content -LiteralPath $Path -Encoding UTF8}
Save-Json $identity (Join-Path $folder 'identity.json')
# 기본적으로 한 리전만 조회하고, AllRegions이면 활성 리전을 열거한다.
$regions=@($Region)
if($AllRegions){$regions=@((Invoke-AwsJson @('ec2','describe-regions') $Region).Regions | ForEach-Object {$_.RegionName})}
# 리전별 조회 명세: 리소스 이름 | CLI 명령 | JMESPath 결과 배열
# 여기 문자열 내부에는 주석을 넣지 않는다.
# 단일 인용 Here-String은 여러 줄을 그대로 보존하며 변수 치환을 하지 않는다.
# JMESPath는 AWS CLI 응답에서 필요한 필드와 배열을 선택하는 표현식이다.
# 예: EC2는 Reservations 내부 Instances를 펼치고 terminated 상태를 제외한다.
$regional=@'
VPC|ec2 describe-vpcs|Vpcs
Subnet|ec2 describe-subnets|Subnets
ENI|ec2 describe-network-interfaces|NetworkInterfaces
IGW|ec2 describe-internet-gateways|InternetGateways
NAT|ec2 describe-nat-gateways|NatGateways[?State!='deleted']
EIP|ec2 describe-addresses|Addresses
SG|ec2 describe-security-groups|SecurityGroups
RouteTable|ec2 describe-route-tables|RouteTables
NACL|ec2 describe-network-acls|NetworkAcls
VPCEndpoint|ec2 describe-vpc-endpoints|VpcEndpoints
EICE|ec2 describe-instance-connect-endpoints|InstanceConnectEndpoints[?State!='delete-complete']
Peering|ec2 describe-vpc-peering-connections|VpcPeeringConnections[?Status.Code!='deleted']
EC2|ec2 describe-instances|Reservations[].Instances[] | [?State.Name!='terminated']
EBS|ec2 describe-volumes|Volumes
EBSSnapshot|ec2 describe-snapshots --owner-ids self|Snapshots
AMI|ec2 describe-images --owners self|Images
KeyPair|ec2 describe-key-pairs|KeyPairs
ASG|autoscaling describe-auto-scaling-groups|AutoScalingGroups
LaunchTemplate|ec2 describe-launch-templates|LaunchTemplates
ALB_NLB|elbv2 describe-load-balancers|LoadBalancers
TargetGroup|elbv2 describe-target-groups|TargetGroups
ClassicELB|elb describe-load-balancers|LoadBalancerDescriptions
RDSInstance|rds describe-db-instances|DBInstances
RDSCluster|rds describe-db-clusters|DBClusters
RDSSnapshot|rds describe-db-snapshots|DBSnapshots
RDSClusterSnapshot|rds describe-db-cluster-snapshots|DBClusterSnapshots
RDSBackup|rds describe-db-cluster-automated-backups|DBClusterAutomatedBackups
DBSubnetGroup|rds describe-db-subnet-groups|DBSubnetGroups
EKS|eks list-clusters|clusters
ECS|ecs list-clusters|clusterArns
ECR|ecr describe-repositories|repositories
AMPWorkspace|amp list-workspaces|workspaces
AMPScraper|amp list-scrapers|scrapers
LogGroup|logs describe-log-groups|logGroups
Alarm|cloudwatch describe-alarms|[MetricAlarms[],CompositeAlarms[]][]
WAF|wafv2 list-web-acls --scope REGIONAL|WebACLs
ACM|acm list-certificates|CertificateSummaryList
Secret|secretsmanager list-secrets|SecretList
KMS|kms list-keys|Keys
Lambda|lambda list-functions|Functions
EFS|efs describe-file-systems|FileSystems
DynamoDB|dynamodb list-tables|TableNames
CloudTrail|cloudtrail describe-trails --no-include-shadow-trails|trailList
'@ -split '\r?\n'
# 글로벌 서비스는 리전별 반복 없이 한 번만 조회한다.
$globalEntries=@'
S3|s3api list-buckets|Buckets
CloudFront|cloudfront list-distributions|DistributionList.Items
Route53|route53 list-hosted-zones|HostedZones
IAMRole|iam list-roles|Roles
IAMUser|iam list-users|Users
CloudFrontWAF|wafv2 list-web-acls --scope CLOUDFRONT|WebACLs
'@ -split '\r?\n'
# 요약과 오류를 각각 리스트에 누적한다.
# List[object]는 결과를 반복적으로 추가할 수 있는 가변 길이 컬렉션이다.
$summary=New-Object 'System.Collections.Generic.List[object]'
$errors=New-Object 'System.Collections.Generic.List[object]'
# 한 리소스 유형을 조회하고 개수와 상세 JSON을 저장한다.
function Scan($Entry,$Location,$Scope){
    # 최대 세 부분만 분리하여 JMESPath 내부 파이프를 보존한다.
    $parts=$Entry -split '\|',3
    # 0번: 리소스 이름, 1번: CLI 명령, 2번: 결과 선택 쿼리.
    $name=$parts[0]; $query=$parts[2]
    try {
        # CLI 명령을 공백 기준으로 분리하고 --query 옵션을 추가한다.
        $argsList=@($parts[1] -split ' ')+@('--query',$query)
        $result=Invoke-AwsJson $argsList $Location
        # null은 제외하고 결과를 배열로 정규화해 Count를 일관되게 계산한다.
        $items=@($result | Where-Object {$null -ne $_})
        # KMS는 키 목록만으로 관리 주체를 알 수 없어 상세 조회한다.
        if($name -eq 'KMS'){
            $items=@(foreach($key in $items){
                try{(Invoke-AwsJson @('kms','describe-key','--key-id',$key.KeyId) $Location).KeyMetadata}
                catch{ $errors.Add([pscustomobject]@{Region=$Location;Resource='KMSDetail';Message=$_.Exception.Message}); $key }
            })
        }
        # 리전과 리소스 유형별 상세 데이터를 독립적인 JSON 파일에 기록한다.
        Save-Json $items (Join-Path $folder "$Scope-$name.json")
        # PSCustomObject를 사용해 CSV로 변환하기 쉬운 구조화된 행을 생성한다.
        $summary.Add([pscustomobject]@{Region=$Scope;Resource=$name;Count=$items.Count;Status='OK'})
        Write-Host "[$Scope] $name : $($items.Count)"
    } catch {
        # 권한 오류나 API 실패를 리소스 0개로 오인하지 않도록 기록한다.
        $summary.Add([pscustomobject]@{Region=$Scope;Resource=$name;Count=$null;Status='ERROR'})
        $errors.Add([pscustomobject]@{Region=$Scope;Resource=$name;Message=$_.Exception.Message})
        Write-Warning "[$Scope] $name : $($_.Exception.Message)"
    }
}
# 리전별 조회 후 글로벌 조회를 수행한다.
# 바깥 반복문은 리전, 안쪽 반복문은 리소스 유형을 순회한다.
foreach($r in $regions){foreach($entry in $regional){Scan $entry $r $r}}
# 글로벌 서비스는 중복 집계를 피하기 위해 한 번만 호출한다.
foreach($entry in $globalEntries){Scan $entry 'us-east-1' 'global'}
# CSV 요약 및 오류 JSON을 저장하고 콘솔에 표를 출력한다.
# Export-Csv는 객체의 속성을 열로 변환하여 요약 보고서를 만든다.
$summary | Export-Csv (Join-Path $folder 'summary.csv') -NoTypeInformation -Encoding UTF8
Save-Json ($errors.ToArray()) (Join-Path $folder 'errors.json')
$summary | Format-Table -AutoSize | Out-Host
Write-Host "Report: $folder"
# 조회가 불완전하면 성공으로 처리하지 않는다.
if($errors.Count){throw "Inventory incomplete: $($errors.Count) error(s). See errors.json"}
