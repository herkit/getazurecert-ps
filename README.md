# GetAzureCert PowerShell

This is a PowerShell module for getting and installing SSL certificates from KeyVault. It will download the certificate, then check if it is not installed and/or close to expiration. If it is then it will attempt to install the certificate.

Example:
```
> Import-Module .\src\Install-CertFromKeyVault.ps1
> Install-CertFromKeyVault -VaultName my-keyvault -CertName my-cert-name
```

