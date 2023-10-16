param(
    [String] [Parameter (Mandatory=$true)] $TemplatePath
)

if (-not (Test-Path $TemplatePath))
{
    Write-Error "'-TemplatePath' parameter is not valid. You have to specify correct Template Path"
    exit 1
}

$ImageTemplateName = [io.path]::GetFileName($TemplatePath).Split(".")[0]

packer validate -syntax-only $TemplatePath

Write-Host "Show Packer Version"
packer --version

Write-Host "Build $ImageTemplateName VM"
packer build -color=false $TemplatePath
