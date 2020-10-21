# GetAzureCert PowerShell

This is a PowerShell module for getting and installing SSL certificates from KeyVault.

Example:
```
> Import-Module .\src\Install-CertFromAzure.ps1
> Install-CertFromAzure -VaultName my-keyvault -CertName my-cert-name
```

