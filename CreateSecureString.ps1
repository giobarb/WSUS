$cred = Get-Credential -UserName 'DOMAIN\USERNAME' -Message "Give me the service accounts name and password credentials."
Write-Host "Give me full qualified domain name of the PC, that will be running the `"LocalDCGPOExport.ps1`" script so I can create a secure string for it."
$computer = Read-Host
Enter-PSSession -ComputerName $computer -credential $cred
Write-Host "Type me a string and I will convert to a SecureString."
$Encrypted = ConvertFrom-SecureString -SecureString (Read-Host -AsSecureString)
echo $Encrypted
Read-Host