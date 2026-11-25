#requires -Version 5.1
[CmdletBinding()]
# 실행 인자: 직접 지정하거나, 생략하면 대화형 입력을 받는다.
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
$scriptDir = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($scriptDir)) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
}
if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
    $OutputRoot = Join-Path $scriptDir '../../aws-inventory-reports'
}
# AWS CLI 설치 여부를 확인한다.
Get-Command aws -ErrorAction Stop | Out-Null

# 호출자가 값을 전달하지 않았을 때만 입력을 요청한다.
# 빈 Profile은 AWS CLI의 기본 자격 증명 체인을 사용한다.
$interactive = -not $NonInteractive -and -not [Console]::IsInputRedirected
if ($interactive -and -not $PSBoundParameters.ContainsKey('Profile')) {
    Write-Host 'Available AWS profiles:'
    & aws configure list-profiles --no-cli-pager
    if ($LASTEXITCODE -ne 0) { Write-Warning 'Could not list configured profiles.' }
    $Profile = (Read-Host 'AWS Profile [current/default]').Trim()
}
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
$common=@('--output','json','--no-cli-pager')
if($Profile){$common+=@('--profile',$Profile)}
# AWS CLI의 JSON 응답을 PowerShell 객체로 변환한다.
# stderr를 별도 파일에 저장하여 정상 JSON과 섞이지 않게 한다.
function Invoke-AwsJson {
    param([string[]]$Arguments,[string]$Location)
    $stderr = [IO.Path]::GetTempFileName()
    try {
        $raw = & aws @Arguments --region $Location @common 2> $stderr
        $code = $LASTEXITCODE
        if ($code -ne 0) {
            throw ("AWS CLI exit code " + $code + ": " + (Get-Content -LiteralPath $stderr -Raw))
        }
        return (($raw -join [Environment]::NewLine) | ConvertFrom-Json)
    } finally {
        Remove-Item -LiteralPath $stderr -Force -ErrorAction SilentlyContinue
    }
}
# STS로 실제 호출 계정 및 IAM 주체를 확인한다.
$identity=Invoke-AwsJson @('sts','get-caller-identity') $Region
# 실행별 고유 보고서 디렉터리를 생성한다.
$folder=Join-Path $OutputRoot ((Get-Date -Format 'yyyyMMdd-HHmmss')+'-'+[guid]::NewGuid().ToString('N').Substring(0,6))
New-Item -ItemType Directory -Path $folder -Force | Out-Null
$folder=(Resolve-Path $folder).Path
# 상세 리소스 객체를 JSON 파일로 저장한다.
function Save-Json($Value,$Path){ConvertTo-Json -InputObject $Value -Depth 100 | Set-Content -LiteralPath $Path -Encoding UTF8}
Save-Json $identity (Join-Path $folder 'identity.json')
# 기본적으로 한 리전만 조회하고, AllRegions이면 활성 리전을 열거한다.
$regions=@($Region)
if($AllRegions){$regions=@((Invoke-AwsJson @('ec2','describe-regions') $Region).Regions | ForEach-Object {$_.RegionName})}
# 리전별 조회 명세: 리소스 이름 | CLI 명령 | JMESPath 결과 배열
# 여기 문자열 내부에는 주석을 넣지 않는다.
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
$summary=New-Object 'System.Collections.Generic.List[object]'
$errors=New-Object 'System.Collections.Generic.List[object]'
# 한 리소스 유형을 조회하고 개수와 상세 JSON을 저장한다.
function Scan($Entry,$Location,$Scope){
    # 최대 세 부분만 분리하여 JMESPath 내부 파이프를 보존한다.
    $parts=$Entry -split '\|',3
    $name=$parts[0]; $query=$parts[2]
    try {
        $argsList=@($parts[1] -split ' ')+@('--query',$query)
        $result=Invoke-AwsJson $argsList $Location
        $items=@($result | Where-Object {$null -ne $_})
        # KMS는 키 목록만으로 관리 주체를 알 수 없어 상세 조회한다.
        if($name -eq 'KMS'){
            $items=@(foreach($key in $items){
                try{(Invoke-AwsJson @('kms','describe-key','--key-id',$key.KeyId) $Location).KeyMetadata}
                catch{ $errors.Add([pscustomobject]@{Region=$Location;Resource='KMSDetail';Message=$_.Exception.Message}); $key }
            })
        }
        Save-Json $items (Join-Path $folder "$Scope-$name.json")
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
foreach($r in $regions){foreach($entry in $regional){Scan $entry $r $r}}
foreach($entry in $globalEntries){Scan $entry 'us-east-1' 'global'}
# CSV 요약 및 오류 JSON을 저장하고 콘솔에 표를 출력한다.
$summary | Export-Csv (Join-Path $folder 'summary.csv') -NoTypeInformation -Encoding UTF8
Save-Json ($errors.ToArray()) (Join-Path $folder 'errors.json')
$summary | Format-Table -AutoSize | Out-Host
Write-Host "Report: $folder"
# 조회가 불완전하면 성공으로 처리하지 않는다.
if($errors.Count){throw "Inventory incomplete: $($errors.Count) error(s). See errors.json"}
