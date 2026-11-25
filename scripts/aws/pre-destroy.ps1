#requires -Version 5.1
[CmdletBinding()]
param([string]$Region='ap-northeast-2',[string]$Profile,[string]$TerraformDir,[switch]$AllRegions)
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
Get-Command terraform -ErrorAction Stop | Out-Null
Push-Location $TerraformDir
try {
    Write-Host 'Checking Terraform workspace and state...'
    & terraform workspace show
    if($LASTEXITCODE){throw 'Workspace check failed'}
    & terraform validate
    if($LASTEXITCODE){throw 'Validation failed'}
    & terraform state list
    if($LASTEXITCODE){throw 'State check failed'}
    & terraform plan -destroy -input=false -detailed-exitcode
    $code=$LASTEXITCODE
    if($code -notin @(0,2)){throw "Destroy plan failed: $code"}
    Write-Host 'Review deletion protection, backups, unmanaged ENIs, and AWS identity before manually approving destroy.'
    Write-Host 'No resources were deleted; no protection settings were changed.'
} finally {Pop-Location}
