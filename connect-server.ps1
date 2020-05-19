# Create your encrypted pw file
$credential = Get-Credential
$credential.Password | ConvertFrom-SecureString | Set-Content C:\Scripts\credfile.txt 

# Declare variables
$SysUser = 'tant-a01\chisu11'
$SysPassword = Get-Content C:\Scripts\credfile.txt | ConvertTo-SecureString
$mycred = New-Object System.Management.Automation.PSCredential -ArgumentList $SysUser, $SysPassword

Connect-VIServer -Server lod-intlvc02.lod.ca.lab -Credential $mycred