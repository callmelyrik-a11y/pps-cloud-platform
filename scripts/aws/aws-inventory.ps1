#requires -Version 5.1
[CmdletBinding()]
param([string]$Region='ap-northeast-2',[string]$Profile,[switch]$AllRegions,[string]$OutputRoot=(Join-Path $PSScriptRoot '../../aws-inventory-reports'))
$ErrorActionPreference='Stop'
Get-Command aws -ErrorAction Stop | Out-Null
$common=@('--output','json','--no-cli-pager')
if($Profile){$common+=@('--profile',$Profile)}
function Invoke-AwsJson {
    param([string[]]$Arguments,[string]$Location)
    $raw=& aws @Arguments --region $Location @common 2>&1
    if($LASTEXITCODE -ne 0){throw ($raw -join [Environment]::NewLine)}
    return (($raw -join [Environment]::NewLine) | ConvertFrom-Json)
}
$identity=Invoke-AwsJson @('sts','get-caller-identity') $Region
$folder=Join-Path $OutputRoot ((Get-Date -Format 'yyyyMMdd-HHmmss')+'-'+[guid]::NewGuid().ToString('N').Substring(0,6))
New-Item -ItemType Directory -Path $folder -Force | Out-Null
$folder=(Resolve-Path $folder).Path
function Save-Json($Value,$Path){ConvertTo-Json -InputObject $Value -Depth 100 | Set-Content -LiteralPath $Path -Encoding UTF8}
Save-Json $identity (Join-Path $folder 'identity.json')
$regions=@($Region)
if($AllRegions){$regions=@((Invoke-AwsJson @('ec2','describe-regions') $Region).Regions | ForEach-Object {$_.RegionName})}
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
$globalEntries=@'
S3|s3api list-buckets|Buckets
CloudFront|cloudfront list-distributions|DistributionList.Items
Route53|route53 list-hosted-zones|HostedZones
IAMRole|iam list-roles|Roles
IAMUser|iam list-users|Users
CloudFrontWAF|wafv2 list-web-acls --scope CLOUDFRONT|WebACLs
'@ -split '\r?\n'
$summary=New-Object 'System.Collections.Generic.List[object]'
$errors=New-Object 'System.Collections.Generic.List[object]'
function Scan($Entry,$Location,$Scope){
    $parts=$Entry -split '\|',3
    $name=$parts[0]; $query=$parts[2]
    try {
        $argsList=@($parts[1] -split ' ')+@('--query',$query)
        $result=Invoke-AwsJson $argsList $Location
        $items=@($result | Where-Object {$null -ne $_})
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
        $summary.Add([pscustomobject]@{Region=$Scope;Resource=$name;Count=$null;Status='ERROR'})
        $errors.Add([pscustomobject]@{Region=$Scope;Resource=$name;Message=$_.Exception.Message})
        Write-Warning "[$Scope] $name : $($_.Exception.Message)"
    }
}
foreach($r in $regions){foreach($entry in $regional){Scan $entry $r $r}}
foreach($entry in $globalEntries){Scan $entry 'us-east-1' 'global'}
$summary | Export-Csv (Join-Path $folder 'summary.csv') -NoTypeInformation -Encoding UTF8
Save-Json ($errors.ToArray()) (Join-Path $folder 'errors.json')
$summary | Format-Table -AutoSize | Out-Host
Write-Host "Report: $folder"
if($errors.Count){throw "Inventory incomplete: $($errors.Count) error(s). See errors.json"}
