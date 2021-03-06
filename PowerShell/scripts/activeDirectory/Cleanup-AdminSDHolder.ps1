<#
  This script will reset the inheritance flag and clear the
  AdminCount attribute for objects no longer protected by the
  AdminSDHolder.

  Output will be written to a csv file that can be imported
  into Excel for reporting.

  The script can run in "report only" mode, so that you are first
  able to understand the current state before taking any action.
  You then have two options:
  1) Manually set each account.
  2) Run this script to take action and reset the inheritance flag
     and clear the AdminCount attribute for all existing accounts
     that have the AdminCount attribute set to 1.
     Any objects that should genuinely be protected will be
     re-protected when the AdminSDHolder next cycles (within 1 hour
     by default).

  Script Name: Cleanup-AdminSDHolder.ps1
  Author: Tony Murray
  Version: 1.0
  Date: 28/08/2013

  Requires PowerShell 2.0 and above.

  Syntax:

    To Report ONLY:
      Cleanup-AdminSDHolder.ps1 -action ReportOnly

    To take action:
      Cleanup-AdminSDHolder.ps1
#>

#-------------------------------------------------------------
param([String]$Action)

if ([String]::IsNullOrEmpty($Action)) {
    $ReportOnly = $False
}
else {
    If ($Action -eq "ReportOnly") {
        $ReportOnly = $True
    }
    else {
        $ReportOnly = $False
    }
}

# Get the script path
$ScriptPath = { Split-Path $MyInvocation.ScriptName }
$ReferenceFile = $(&$ScriptPath) + "\AdminSDHolderReport.csv"

$array = @()
$objectclasses = @{}

$ProtectedGroups = @("Schema Admins", "Enterprise Admins", "Cert Publishers", "Domain Admins", "Account Operators", "Print Operators", "Administrators", "Server Operators", "Backup Operators")

# Import the AD module
Import-Module ActiveDirectory

# Find objects that appear to be protected in AD
$probjs = Get-ADObject -LDAPFilter "(admincount=1)" | sort-object ObjectClass, Name
$bcount = $probjs.count
if ($bcount) {
    If ($ReportOnly -eq $False) {
        Write-Host -ForegroundColor Green "Protected object count before change is $bcount"
    }
    else {
        Write-Host -ForegroundColor Green "Protected object count is $bcount"
    } # end if
}
else {
    Write-Host -ForegroundColor Green "No objects are currently protected - nothing to do"
    exit
} # end if
Write-Host " "

# Change to the AD drive
Set-Location AD:

# Loop through protected objets to set inheritance flag
# and clear the adminCount value
foreach ($probj in $probjs) {
    $dn = $probj.distinguishedname
    If ($($probj.name).Contains("CNF:") -eq $False) {
        $name = $($probj.name)
    }
    else {
        $name = [string]::join("\0A", ($($probj.name).Split("`n")))
    } # end if
    $class = $probj.ObjectClass

    # Create a hashtable to capture a count of each objectclass
    If (!($objectclasses.ContainsKey($class))) {
        $objectclasses = $objectclasses + @{$class = 1 }
    }
    else {
        $value = $objectclasses.Get_Item($class)
        $value ++
        $objectclasses.Set_Item($class, $value)
    } # end if

    If ($dn.Contains("CNF:") -eq $False) {
        If ($ProtectedGroups -notcontains $name) {
            $acl = Get-Acl $dn
            if ($acl.AreAccessRulesProtected) {
                If ($ReportOnly -eq $False) {
                    Write-Host -ForegroundColor Yellow "$class`t$dn has inheritance blocked - we will remove the block"
                    $acl.SetAccessRuleProtection($false, $false);
                    #set-acl -aclobject $acl $dn
                    # We need to clear the adminCount attribute too
                    #Set-ADObject -Identity $dn -Clear adminCount
                }
                else {
                    Write-Host -ForegroundColor Yellow "$class`t$dn has inheritance blocked"
                } # end if
            } # end if
        }
        else {
            Write-Host -ForegroundColor Yellow "$class`t$dn is a default protected group"
        } # end if
    }
    else {
        Write-Host -ForegroundColor Red "$class`t$dn cannot be processed"
    }# end if

    $obj = New-Object -TypeName PSObject
    $obj | Add-Member -MemberType NoteProperty -Name "Class" -Value $class
    $obj | Add-Member -MemberType NoteProperty -Name "Name" -Value $name
    $obj | Add-Member -MemberType NoteProperty -Name "DN" -Value $dn
    $array += $obj

} # end foreach    

Write-Host -ForegroundColor Green "`nA break down of the $bcount objects processed:"
$objectclasses.GetEnumerator() | Sort-Object Name | ForEach-Object { 
    Write-Host -ForegroundColor Green "- $($_.key): $($_.value)"
}

# Write-Output $array | Format-Table
$array | Export-Csv -notype -path "$ReferenceFile" -Delimiter ';'

# Remove the quotes
(Get-Content "$ReferenceFile") | ForEach-Object { $_ -replace '"', "" } | Out-File "$ReferenceFile" -Force -Encoding ascii

If ($ReportOnly -eq $False) {
    # Count the number of protected objects
    $acount = (Get-ADObject -LDAPFilter "(admincount=1)").count
    Write-Host " "
    if ($acount) {
        Write-Host -ForegroundColor Green "Protected object count after change is $acount"
    }
    else {
        Write-Host -ForegroundColor Green "No objects are currently protected"
    } # end if
} # end if
