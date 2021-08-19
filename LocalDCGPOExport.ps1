Clear-Host

function Get-LoggedUser {

    param (
        $ComputerName
    )

    Get-WinEvent  -Computer $ComputerName -FilterHashtable @{Logname='Security';ID=4672} -MaxEvents 1 |
    Select-Object @{N='User';E={$_.Properties[1].Value}}
} #From event log, via Martin on Webex

#Initial data, currently XML
$Config = Get-Content -raw C:\TS_WSUS\config.json | ConvertFrom-Json
Get-GPO -Name $Config.GPOName | Get-GPOReport -ReportType XML > C:\TS-WSUS\GPOXport.xml

#Find the Div with the SecGroups
$Output = Get-Content -Raw .\GPOXport.xml | 
          Select-String -Pattern '<SOMPath>(.|\n)*?<\/SOMPath>' -AllMatches | 
          Select-Object -ExpandProperty Matches | 
          Select-Object -ExpandProperty Value
#Get the specifics groups inside of the XML Tags

$DomainIncludedInGPO = $NULL
$ToRemove = '<SOMPath>','</SOMPath>'
$OUList = @()
#Go through each match and remove extra XML shite

foreach($Match in $Output)
{
    foreach($Remover in $ToRemove)
    {
        $Match = $Match -replace $Remover
    }

    if($Match.Split('/') -eq $Match)
    {
        $DomainIncludedInGPO = $Match
    }
    else
    {
        $OUList += $Match
    }
}

#FQDN - [System.Net.Dns]::GetHostByName("Contoso-PC1")

if($NULL -ne $DomainIncludedInGPO)
{
    $Output = 
    Get-ADComputer -Filter "*" -Properties *
}
else
{
    $Output = @()
    $AllOUs = Get-ADOrganizationalUnit -Filter * -Properties * | Select-Object Name,DistinguishedName
    foreach($OU in $OUList)
    {
        $OU = $OU.Split('/')
        $OU = $OU[-1]
        foreach($SingularOU in $AllOUs)
        {
            if($SingularOU.Name -eq $OU)
            {
                Write-Output $SingularOU.DistinguishedName
                $Output += Get-ADComputer -Filter {(Enabled -eq $TRUE)} -SearchBase $SingularOU.DistinguishedName -Properties *
                break
            }
        }
    }
}

#$Output | Select-Object Name
$ToAdd = ""
$ToSend = @()
foreach($Computer in $Output)
{
    Write-Output "working on $($Computer.DNSHostname)"
    $ToAdd = [PSCustomObject]@{
        Name = $Computer.Name
        DistinguishedName = $Computer.DistinguishedName
        LastLogonDate     = $Computer.LastLogonDate
        DNSHostName       = $Computer.DNSHostName
        OperatingSystem   = $Computer.OperatingSystem
        Enabled           = $Computer.Enabled
        LastLoggedUser    = "" #try { Get-LoggedUser -ComputerName $Computer.Name } 
                               #catch{ "Unable to retrieve LastLoggedUser, WinRM possibly not setup. Error message is $($Error[0])" }; 
        Domain            = $Computer.DNSHostName.Split('.')[-2]
    }
    $ToSend += $ToAdd
}
$ToSend = $ToSend | Select-Object * -Unique
$ToSend | Export-Csv -Path C:\TS_WSUS\$(Get-Date -Format "yyyyMMdd")_$($env:USERDOMAIN)_FROMDC.csv -NoTypeInformation


#get mail params from config.json, securestring in as well if needed
#Everything but attachments into config.json
#Batch to create SecureString

$mailParams = @{
    SmtpServer                 = $Config.SMTP
    Port                       = $Config.Port # '25' if not using TLS, '587' if using TLS 
    UseSSL                     = $Config.SSL ## required $TRUE for TLS
    From                       = $Config.MailFrom
    To                         = $Config.MailTo
    Subject                    = $Config.Subject
    Attachments                = ".\$(Get-Date -Format "yyyyMMdd")_$($env:USERDOMAIN)_FROMDC.csv"
}

# Send the message, only from GPO on local DC
if($Config.SecureString -ne "") {
    [pscredential]$credObject = New-Object System.Management.Automation.PSCredential ($Config.MailFrom, $($Config.SecureString | ConvertTo-SecureString))
    Send-MailMessage @mailParams -Credential $credObject
}
else {Send-MailMessage @mailParams}