# GetAzureCert PowerShell

This is a PowerShell module for getting and installing SSL certificates from KeyVault.

Example:
```
> Import-Module .\src\Install-CertFromKeyVault.ps1
> Install-CertFromKeyVault -VaultName my-keyvault -CertName my-cert-name
```

