Param(
    [Parameter(Mandatory=$false,
                ValueFromPipelineByPropertyName=$true,
                Position=0)]
    $GivenFolder = $NULL
)

function Get-StatusOfComputer{
    param(
    $Status
    )
    switch ($Status)
    {
        "==" {return "Computer is present in both WSUS and AD."}
        "=>" {return "Computer is not present in WSUS."}
        "<=" {return "Computer is not present in AD."}
        default {"N/A"}
    }
} #Returns the status of the computer

function Get-DateForMember{
    param(
    $Status,
    $WSUSComputer
    )
    switch ($Status)
    {
        "==" {$WSUSComputer.LastSyncTime}
        default {"N/A"}
    }
} #Returns the date of LastSyncTime for export, need to loop through

function Get-MemberForExport {
    param (
        $WSUSComputer,
        $GPOComupter,
        $Status
    )
    $Member = [PSCustomObject]@{
        FQDN = $GPOComupter.DNSHostName
        LastLogonDate = $GPOComupter.LastLogonDate
        LastLoggedUser = $GPOComupter.LastLoggedUser
        DistinguishedName = $GPOComupter.DistinguishedName
        Status = Get-StatusOfComputer -Status $Status
        Date = Get-DateForMember -Status $Status -WSUSComputer $WSUSComputer
    }
    return $Member
} #Returns member for export, need to loop through to get all

function Write-Outputs{
    param(
        $ExportToARCH,
        $ExportToOUTERR,
        $Header,
        $Domain,
        $Date
    )

    $ToWrite = "
<!DOCTYPE html>
<html>
<head>
<style>
table, th, td {
  border: 1px solid black;
  border-collapse: collapse;
}
th, td {
  padding: 5px;
}
th {
  text-align: left;
}
</style>
</head>
<body>

<h2>$($Header)</h2>
<p>Output of comparing the WSUS server from $($env:COMPUTERNAME), from file $($Report.Name) which is from $($Domain)</p>
<table style=`"width:100%`">
  <tr>
    <th>FQDN</th>
    <th>Status</th>
    <th>LastLogonDate</th> 
    <th>LastLoggedUser</th>
    <th>DistinguishedName</th>
    <th>Date</th>
  </tr>
" #Header
    foreach($Line in $ExportToOUTERR)
    {
        $ToWrite += "
  <tr>
    <th>$($Line.FQDN)</th>
    <th>$($Line.Status)</th>
    <th>$($Line.LastLogonDate)</th> 
    <th>$($Line.LastLoggedUser)</th>
    <th>$($Line.DistinguishedName)</th>
    <th>$($Line.Date)</th>
  </tr>
" #Data
    }
    $ToWrite += " 
</table>
</body>
</html>
" #Footer
    $ToWrite | New-Item C:\TS_WSUS\OUT_ERR\$($Domain)\OUTERR_$(Get-Date -Format "yyyyMMdd")_$($Domain).html -Force | Out-Null
    $ExportToARCH | Export-Csv -Path C:\TS_WSUS\ARCH\$($Domain)\ARCH_$(Get-Date -Format "yyyyMMdd")_$($Domain).csv -NoTypeInformation -Force
} #Creates the HTML file that will be posted into OUT_ERR, Status after FQDN

function Write-Error{
    param(
    $FolderName,
    $Header
    )
    $ToWrite = "
<!DOCTYPE html>
<html>
<head>
<style>
table, th, td {
  border: 1px solid black;
  border-collapse: collapse;
}
th, td {
  padding: 5px;
}
th {
  text-align: left;
}
</style>
</head>
<body>

<h2>$($Header)</h2>

<h3>$($FolderName) has no .csv file, cannot compare with WSUS.</h3>

</body>
</html>" #Content for empty folders.
    $ToWrite | New-Item C:\TS_WSUS\OUT_ERR\$($FolderName)\OUTERR_$(Get-Date -Format "yyyyMMdd")_$($FolderName).html -Force | Out-Null
} #For folders that have no .csv file

function Compare-Dates {
    param(
    $Report
    )
    $Today = Get-Date -DisplayHint Date
    $Today = $Today.AddDays(-30)
    $DateOfReport = [datetime]::parseexact($Report.Name.Split('_')[0], 'yyyyMMdd', $null)
    if($DateOfReport -gt $Today)
    {
        return $DateOfReport.GetDateTimeFormats()[0]
    }
    else
    {
        return "$($DateOfReport.GetDateTimeFormats()[0]), this date is over 30 days old."
    }
} #Checks if the date of the file is more than 30 days.

Clear-Host
$ContentOfTSWSUS =  if($GivenFolder -ne $NULL){Get-ChildItem C:\TS_WSUS -Filter $GivenFolder | Select-Object Name,FullName}else{Get-ChildItem C:\TS_WSUS -Exclude "ARCH","OUT_ERR" | Select-Object Name,FullName}
$WSUSComputers = ""
$GPOReport = ""
$Comparison = ""
$ExportToARCH = @()
$ExportToOUTERR = @()
$ToAdd = ""
$ClientReports = @()

# Also I just discovered that this expression is perfectly legal
# $penis = if("penis" -eq "isbig"){"it's massive"} else{"it's miniscular"}
# Someone help me, also Compare-Object is exactly what I needed, and I never knew I needed it

foreach($Folder in $ContentOfTSWSUS)
{
    $Items = Get-ChildItem C:\TS_WSUS\$($Folder.Name) -Filter "*.csv" | Select-Object Name,Fullname
    if($NULL -eq $Items) {Write-Error -FolderName $Folder.Name -Header "$($Folder.Name) from $(Get-Date -Format `"yyyyMMdd`")"; Write-Warning "$($Folder.Name) is empty"}
    else{$ClientReports += $Items}
}

foreach($Report in $ClientReports)
{
    
    $GPOReport = Import-Csv $Report.FullName
    $WSUSComputers = Get-WsusComputer -NameIncludes $GPOReport[0].Domain
    $GPOReport[0].Domain

    if((Get-WsusComputer -NameIncludes $GPOReport[0].Domain) -eq "No computers available.") #If there are no Computer found in WSUS
    {
        #Add all PCs to Status "Computer Was not found in WSUS." $Status = "=>"
        foreach($Computer in $GPOReport)
        {
            $ToAdd = Get-MemberForExport -Status "=>" -WSUSComputer "" -GPOComupter $Computer
            $ExportToARCH += $ToAdd
            $ExportToOUTERR += $ToAdd
        }
    } 
    else #If there are computers found in WSUS process them
    {
        $Comparison = Compare-Object -DifferenceObject $GPOReport.DNSHostName.ToLower() -ReferenceObject $WSUSComputers.FullDomainName.ToLower() -IncludeEqual
        foreach ($ComparedObject in $Comparison)
        {
            switch ($ComparedObject.SideIndicator.ToString())
            {
                ("==") 
                {
                    #Write-Output "$($ComparedObject.InputObject) is present in both"
                    $ToAdd = Get-MemberForExport -Status "==" -WSUSComputer ($WSUSComputers | Where-Object {$_.FullDomainName -eq $ComparedObject.InputObject}) -GPOComupter  ($GPOReport | Where-Object {$_.DNSHostName -eq $ComparedObject.InputObject})
                    $ExportToARCH += $ToAdd
                    break
                }
                ("=>") 
                {
                    #Write-Output "$($ComparedObject.InputObject) is only in GPO"
                    $ToAdd = Get-MemberForExport -Status "=>" -WSUSComputer ($WSUSComputers | Where-Object {$_.FullDomainName -eq $ComparedObject.InputObject}) -GPOComupter  ($GPOReport | Where-Object {$_.DNSHostName -eq $ComparedObject.InputObject})
                    $ExportToARCH += $ToAdd
                    $ExportToOUTERR += $ToAdd
                    break
                }
                ("<=")
                {
                    #Write-Output "$($ComparedObject.InputObject) is only in WSUS"
                    $ToAdd = Get-MemberForExport -Status "<=" -WSUSComputer ($WSUSComputers | Where-Object {$_.FullDomainName -eq $ComparedObject.InputObject}) -GPOComupter  ($GPOReport | Where-Object {$_.DNSHostName -eq $ComparedObject.InputObject})
                    $ExportToARCH += $ToAdd
                    $ExportToOUTERR += $ToAdd
                    break
                }
            }
        }
    
    } 
    Write-Outputs -ExportToARCH $ExportToARCH -ExportToOUTERR $ExportToOUTERR -Header "CSV report from DC, made on $(Compare-Dates -Report $Report)" -Domain $GPOReport[0].Domain
    $ExportToARCH = @()
    $ExportToOUTERR = @()
    $ToAdd = ""
    Remove-Item $Report.FullName
}

Write-Host "Press Enter to exit"
Read-Host