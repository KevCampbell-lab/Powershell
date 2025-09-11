#Enter new or existing OU name
$ouName = Read-Host "Enter NEW OU name (e.g., IT)" `
$domain = (Get-ADDomain).DistinguishedName

#User input new OU name (from custom function)
$ouDN = Create-NewOU -name $ouName -ParentDN $domain

#Stop creating new OU if it exists
if (-not (Get-ADOrganizationalUnit -Identity $ouDN -EA SilentlyContinue)) {
  New-ADOrganizationalUnit -Name $ouName -Path ("OU=$ouName," + $domain) -ProtectedFromAccidentalDeletion:$false -EA Stop
}

#Sets the User Password and directs script to txt file for names
$UserPassword = ConvertTo-SecureString $UserPassword -AsPlainText -Force

#Import CSV Rows
$FilePath = Pick-FilePath
$rows = Import-Csv $FilePath 

#Counters
$ok = 0; $total = 0

#Loops the usernames to create a AD user with the names from the txt file
foreach ($f in $rows){
    try {
    $first = $f.FirstName
    $last =  $f.LastName
    if (-not $first -or -not $last) { throw "Missing First/Last Name in CSV row."} # Will report failure by each row
    $username = "$($first).$($last)"
    $total++ #counter for the summary

    New-ADUser `
        -SamAccountName $username `
        -UserPrincipalName "$username@$upnSuffix" `
        -GivenName $first `
        -Surname $last `
        -DisplayName "$first $last" `
        -Name "$first $last" `
        -EmployeeID $username `
        -AccountPassword $UserPassword `
        -ChangePasswordAtLogon $true `
        -Path $ouDN `
        -Enabled $true `
        -ErrorAction Stop
$ok++ #counter of completed users in the summary
         Write-Host "Creating User: $username" -BackgroundColor Black -ForegroundColor Yellow
} catch {
    Write-Warning "Failed to add $($r.firstname)$($r.LastName): $($_.Exception.Message)"
        }
}

Write-Host "`nSummary:" -ForegroundColor Yellow            
Write-Host " OU Name  : $ouname" 
Write-Host " CSV Path : $Filepath"
Write-Host ("{0} out of {1} users successfully added" -f $ok, $total) -BackgroundColor Green -ForegroundColor Black


