function Install-CertFromKeyVault
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string] $VaultName,
        [Parameter(Mandatory=$true)]
        [string] $CertName
    )

    Process
    {
        $tempCertPath = $CertName + ".pfx.b64"
        $certPath = $CertName + ".pfx"

        if (Test-Path $tempCertPath) {
            Remove-Item $tempCertPath
        }

        az keyvault secret download --vault-name $VaultName -n $CertName --file $tempCertPath
        $b64 = Get-Content $tempCertPath
        $data = [System.Convert]::FromBase64String($b64)
        [System.IO.File]::WriteAllBytes($certPath, $data)

        $cert = Get-PfxCertificate -FilePath $certPath

        $installed = Get-ChildItem -Path Cert:\LocalMachine -Recurse | Where-Object -Property Subject -EQ $cert.Subject
        $expiring = Get-ChildItem -Path Cert:\LocalMachine -Recurse -ExpiringInDays 5 | Where-Object -Property Subject -EQ $cert.Subject

        if (-Not $installed) { 
            Import-PfxCertificate -FilePath $certPath -CertStoreLocation cert:\LocalMachine\My 
        } else {
            if ($expiring) { 
                Import-PfxCertificate -FilePath $certPath -CertStoreLocation cert:\LocalMachine\My } else { Write-Host "Certificate exists and is not close to expiring" 
            }
        }

        Remove-Item $tempCertPath
        Remove-Item $certPath 
    }
}
