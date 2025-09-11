#Enter new or existing OU name
$ouName = Read-Host "Enter NEW OU name (e.g., IT)" `
$domain = (Get-ADDomain).DistinguishedName
Create-NewOU -name $ouName -ParentDN $domain

#Sets the User Password and directs script to txt file for names
$UserPassword = "Password1"
$UserPassword = ConvertTo-SecureString $UserPassword -AsPlainText -Force

#Import file path
$FilePath = Pick-FilePath
Import-Csv $FilePath 


#Checks to see if OU (Line #2) exists, if not then new OU will be created then prompted "OU $ouName created in $domain" 
IF(-not (Get-ADOrganizationalUnit -LDAPFilter "$ouName" -SearchBase $domain -ErrorAction SilentlyContinue)) {
   New-ADOrganizationalUnit -Name $ouName -path $domain -ProtectedFromAccidentalDeletion $false
   Write-Host "OU $ouName created in $domain " -BackgroundColor Green -ForegroundColor Black 
}

#Loops the usernames to create a AD user with the names from the txt file
foreach ($f in $Filepath){
    $first = $f.FirstName
    $last =  $f.LastName
    #$username = $first + "." + $last
    $username = "$($first).$($last)"
    $email = "$($username)@$($maildomain)"
    Write-Host "Creating User: $($username)" -BackgroundColor Black -ForegroundColor Yellow

    New-ADUser -AccountPassword $UserPassword `
               -GivenName $first `
               -Surname $last `
               -DisplayName $username `
               -Name $username `
               -EmployeeID $username `
               -PasswordNeverExpires $true `
               -Path ("$ouName"+(Get-ADDomain).DistinguishedName) `
               -Enabled $true 
} 
$ok = 0; $total = 0
$rows | ForEach-Object {
    try {
        $total++
        New-ADUser @params -ErrorAction Stop
        $ok++
        } catch { }
}
                                
Write-Host "`nAction Complete: New Users added to OU! " -BackgroundColor Green -ForegroundColor Black         
Write-Host "`nSummary:" -BackgroundColor Green -ForegroundColor Black
Write-Host " OU Name  : $ouname" 
Write-Host " CSV Path : $Filepath"
Write-Host ("{0} out of {1} users successfully added" -f $ok, $total) 

