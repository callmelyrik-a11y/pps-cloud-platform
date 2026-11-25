#requires -Version 5.1
[CmdletBinding()]
param([string]$Region='ap-northeast-2',[string]$Profile,[string]$VpcId,[switch]$AllRegions,[switch]$CheckTerraform,[string]$TerraformDir)
$ErrorActionPreference='Stop'
$scriptDir = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($scriptDir)) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
}
if ([string]::IsNullOrWhiteSpace($TerraformDir)) {
    $TerraformDir = Join-Path $scriptDir '../../infra/terraform/environments/dev'
}
$parameters=@{Region=$Region;AllRegions=$AllRegions}
if($Profile){$parameters.Profile=$Profile}
& (Join-Path $scriptDir 'aws-inventory.ps1') @parameters
$blocked=$false
if($VpcId){
    $opts=@('--region',$Region,'--output','json','--no-cli-pager')
    if($Profile){$opts+=@('--profile',$Profile)}
    $raw=& aws ec2 describe-vpcs --filters "Name=vpc-id,Values=$VpcId" @opts
    if($LASTEXITCODE){throw 'VPC query failed'}
    $vpcs=@(($raw -join [Environment]::NewLine | ConvertFrom-Json).Vpcs | Where-Object {$_})
    if($vpcs.Count){
        $blocked=$true
        Write-Warning "VPC still exists: $VpcId"
        & aws ec2 describe-network-interfaces --filters "Name=vpc-id,Values=$VpcId" @opts
        if($LASTEXITCODE){throw 'ENI query failed'}
    }else{Write-Host "Target VPC not found: $VpcId"}
}
if($CheckTerraform){
    Push-Location $TerraformDir
    try{
        & terraform validate
        if($LASTEXITCODE){throw 'Validation failed'}
        & terraform state list
        if($LASTEXITCODE){throw 'State query failed'}
        & terraform plan -destroy -input=false -detailed-exitcode
        $code=$LASTEXITCODE
        if($code -eq 2){$blocked=$true;Write-Warning 'Terraform still has planned destroy changes'}
        elseif($code -ne 0){throw "Terraform plan failed: $code"}
    }finally{Pop-Location}
}
Write-Host 'Review inventory summary for remaining resources, including S3, logs, backups and KMS. Nonempty inventory is not necessarily an error.'
if($blocked){throw 'Target verification incomplete: remaining resources detected'}
