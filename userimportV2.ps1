#Enter new or existing OU name
$ouName = "LabUsers"
$domain = Pick-FilePath
#@(Get-AdDomain).distinguishedName


#Sets the User Password and directs script to txt file for names
$UserPassword = "Password1"
$UserPassword = ConvertTo-SecureString $UserPassword -AsPlainText -Force

#Import file path
$UserFullName = Import-Csv 'C:\Users\Administrator\Desktop\ADUser\ADUsers.csv'

#Checks to see if OU (Line #2) exists, if not then new OU will be created then prompted "OU $ouName created in $domain" 
IF(-not (Get-ADOrganizationalUnit -LDAPFilter "(ou=$ouName)" -SearchBase $domain -ErrorAction SilentlyContinue)) {
    New-ADOrganizationalUnit -Name $ouName -path $domain -ProtectedFromAccidentalDeletion $false
    Write-Host "OU $ouName created in $domain " -BackgroundColor Green -ForegroundColor Black 
    }

#Loops the usernames to create a AD user with the names from the txt file
foreach ($n in $UserFullName){
    $first = $n.FirstName
    $last =  $n.LastName
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
               -Path ("ou=UsersLab," + (Get-ADDomain).distinguishedName) `
               -Enabled $true 
               Write-Host "Action Complete: New Users added to OU! " -BackgroundColor Green -ForegroundColor Black         
} 