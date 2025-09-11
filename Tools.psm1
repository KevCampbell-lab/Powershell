function Resolve-OU {
    param([Parameter(Mandatory)][string]$InputOU)
    if ($InputOU -match 'DC=') {return $InputOU} #already DN
    $base = (Get-ADDomain).DistinguishedName
    $ous = Get-ADOrganizationalUnit -LDAPFilter "(name=$InputOU)" -SearchBase $base -SearchScope Subtree
    if (-not $ous) { Write-Output "OU named '$InputOU' not found under $base." }
    if ($ous.Count -ge 1) {
        $list = $ous | Select-Object -ExpandProperty DistinguishedName
        Write-Output "Multiple OUs named 'InputOU' found: `n-" + ($list -join "`n-")
    }
    return $ous.DistingushedName
}

function Select-ExistingOU {
    try {
        $sel = Get-ADOrganizationalUnit -LDAPFilter "(objectClass=organizationalUnit)" -SearchScope Subtree |
        Select-Object Name, Distinguished Name |
        Out-GridView -Title "Pick an existing OU" -PassThru
    if ($sel) { return $sel.DistinguishedName }
    Write-Output "No OU selected."
  } catch {
    $typed = Read-Host "Enter OU Name (Such as 'UsersLab' OR full DN like OU=UsersLab,DC=corp,DC=example,DC=com)" 
    return (Resolve-OU -InputOU $typed)
  }
}

function Create-NewOU {
    param(
        [Parameter(Mandatory)][string]$ouname,
        [Parameter(Mandatory)][string]$ParentDN
    )

    $newDN = "OU=$ouname,$ParentDN"
    #If OU exists, just return it
    $existing = Get-ADOrganizationalUnit -Identity $newDN -ErrorAction SilentlyContinue 
    if ($existing) {
    Write-Host "OU already exists: $newDN" -BackgroundColor DarkYellow -ForegroundColor DarkRed
    }
    return $newDN
}

function Pick-FilePath {
    param(
        [string]$Title ="Select CSV",
        [string]$Filter = "CSV files (*.csv)|*.csv|All files (*.*)|*.*"
        )

try {
    Add-Type -AssemblyName System.Windows.Forms
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Title = $Title
    $dlg.Filter = $Filter
    $dlg.InitialDirectory = [Environment]::GetFolderPath('Desktop')

    if ($dlg.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
        throw "No file selected."
    }
    return $dlg.FileName
} catch {
    while ($true) {
        $p = Read-Host "$Title (type/paste full path)"
        if ([string]::IsNullOrWhiteSpace($p)) { Write-Warning "Path required."; continue }
        if (Test-Path $p -PathType Leaf) { return (Resolve-Path $p).Path }
        Write-Warning "File not found: $p"
    }
  }
}