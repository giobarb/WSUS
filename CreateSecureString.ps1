Write-Host "Type me a string and I will convert to a SecureString."
$Encrypted = ConvertFrom-SecureString -SecureString (Read-Host -AsSecureString)
echo $Encrypted
Read-Host