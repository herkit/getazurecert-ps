function Install-CertFromKeyVault
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string] $VaultName,
        [Parameter(Mandatory=$true)]
        [string] $CertName,
        [Parameter(Mandatory=$true)]
        [string] $CertDomain
    )

    Process
    {
        $wd = Get-Location
        $tempCertPath = "$wd\$CertName.pfx.b64"
        $certPath = "$wd\$CertName.pfx"

        if (Test-Path $tempCertPath) {
            Remove-Item $tempCertPath
        }

        & az keyvault secret download --vault-name $VaultName -n $CertName --file $tempCertPath
        if ($LASTEXITCODE -ne 0) {
            'an error occurred while downloading certificate'
            exit 1
        }
        $b64 = Get-Content $tempCertPath
        $data = [System.Convert]::FromBase64String($b64)
        [System.IO.File]::WriteAllBytes($certPath, $data)

        $cert = Get-PfxCertificate -FilePath $certPath

        $installed = Get-ChildItem -Path Cert:\LocalMachine -Recurse | Where-Object -Property Thumbprint -EQ $cert.Thumbprint
        $expiring = Get-ChildItem -Path Cert:\LocalMachine -Recurse | where { $_.notafter -le (Get-Date).AddDays(5) } | Where-Object -Property Subject -EQ $cert.Subject

        if (-Not $installed) { 
            Import-PfxCertificate -FilePath $certPath -CertStoreLocation cert:\LocalMachine\My 

            Get-WebBinding -Protocol Https | Where-Object {$_.bindingInformation -match "^(\*\:443\:[a-zA-Z0-9-_]{0,62}\.)$CertDomain" -and $_.sslFlags -GT 0} | select -expand bindingInformation | %{$_.split(':')[-1]} | ForEach-Object {
				        $binding = Get-WebBinding -HostHeader $_ -Protocol Https | Where-Object {$_.sslFlags -GT 0}
				        if ($binding) {
					          $binding.AddSslCertificate($cert.Thumbprint, "My")
				        }
			      }
        } else {
            if ($expiring) { 
                Import-PfxCertificate -FilePath $certPath -CertStoreLocation cert:\LocalMachine\My 
                Remove-Item $expiring
            } 
            else 
            {
                Write-Host "Certificate exists and is not close to expiring" 
                Get-WebBinding -Protocol Https | Where-Object {$_.bindingInformation -match "^(\*\:443\:[a-zA-Z0-9-_]{0,62}\.)$CertDomain" -and $_.sslFlags -GT 0} | select -expand bindingInformation | %{$_.split(':')[-1]} | ForEach-Object {
				            $binding = Get-WebBinding -HostHeader $_ -Protocol Https | Where-Object {$_.sslFlags -GT 0}
				            if ($binding) {
					              $binding.AddSslCertificate($cert.Thumbprint, "My")
				            }
			          }
            }
        }

        Remove-Item $tempCertPath
        Remove-Item $certPath 
    }
}

Export-ModuleMember -Function Install-CertFromKeyVault