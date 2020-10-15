﻿<#
				"Satnaam WaheGuru Ji"

	Author  : Aman Dhally
	Email	: amandhally@gmail.com
	Date	: 21-august-2012
	Time	: 13:20
	Script	: Active Directory Reports
	Purpose	: Active Directory Reporting to Excel
	website : www.amandhally.net
	twitter : https://twitter.com/#!/AmanDhally

				/^(o.o)^\  V.1

#>

# Import Active Directory Module
Import-Module -Name ActiveDirectory

# variables
$date = (Get-Date).tostring()
$week = (Get-Date).AddDays(-7)

# Active Directory Task Starts

Write-Host "Getting users created within a week."
$ADuserInWeek = Get-ADUser -Filter * -Properties * | Where-Object { $_.whenCreated -ge $week } | Select-Object Name, whenCreated
Write-Host "Getting users those password are Never expirpes"
$passNeverExpire = Get-ADUser -Filter * -Properties PasswordNeverExpires | Where-Object { $_.PasswordNeverExpires -eq $true } | Select-Object Name | Sort-Object
Write-Host "getting Computer Accounts"
$inAcComp = Get-ADComputer -Filter "Enabled -eq '$false'" | Select-Object Name
Write-Host "getting inactive User accounts"
$inacUser = Get-ADUser -Filter "Enabled -eq '$false'" | Select-Object Name


# Create a Excel Workspace
$excel = New-Object -ComObject Excel.Application

# make excel visible
$excel.visible = $true

# add a new blank worksheet
$workbook = $excel.Workbooks.add()

# Adding Sheets
$s1 = $workbook.sheets | Where-Object { $_.name -eq 'Sheet1' }
$s1.Delete()



# Sheet 2
# Find All Users those are created with in a Week
$s2 = $workbook.sheets | Where-Object { $_.name -eq 'Sheet2' }
$s2.name = "User Created in week"

#  Add information ot sheet 2
$cells = $s2.Cells
$s2.range("C1:C1").font.bold = "true"
$s2.range("C1:C1").font.size = 18
$s2.range("C1:C1").cells = "List of Active Directory User Account those are created with-in one Week."
$s2.range("A3:A3").cells = "Name"
$s2.range("A3:A3").font.bold = "true"
$s2.range("B3:B3").cells = "When Created"
$s2.range("B3:B3").font.bold = "true"

$row = 3
$col1 = 1
$col2 = 2
Foreach ($user in $ADuserInWeek ) {
	$row++
	$col1 = 1
	$col2 = 2
	$cells.item($Row, $col1) = $user.Name
	$col1++
	$cells.item($Row, $col2) = $user.whenCreated
	$col2++

}
$s2.range("A3:b3").EntireColumn.autofit() | out-Null

#Sheet 3 Users with Password Never Expire Set
$s3 = $workbook.sheets | Where-Object { $_.name -eq 'Sheet3' }
$s3.name = "Pass Never Expire"

#  Add information ot sheet 2
$cells = $s3.Cells
$s3.range("C1:C1").font.bold = "true"
$s3.range("C1:C1").font.size = 18
$s3.range("C1:C1").cells = "List of Active Directory Users those Password are set to never expire.."
$s3.range("A3:A3").cells = "Name"
$s3.range("A3:A3").font.bold = "true"

$row1 = 3
$col3 = 1
Foreach ( $Passw in $passNeverExpire) {
	$row1++
	$col3 = 1
	$cells.item($Row1, $col3) = $Passw.Name
	$col3++
}
$s3.range("A3:A3").EntireColumn.autofit() | out-Null

### Adding Sheet 4
$s4 = $workbook.Sheets.add()
$s4.name = "Inactive Computers"
$cells = $s4.Cells
$s4.range("C1:C1").font.bold = "true"
$s4.range("C1:C1").font.size = 18
$s4.range("C1:C1").cells = "List of Inactive Computer Acccounts"
$s4.range("A3:A3").cells = "Name"
$s4.range("A3:A3").font.bold = "true"

$row4 = 3
$col4 = 1
Foreach ( $Com in $inAcComp) {
	$row4++
	$col4 = 1
	$cells.item($Row4, $col4) = $Com.Name
	$col4++
}
$s4.range("A3:A3").EntireColumn.autofit() | out-Null

## Sheet 5
$s5 = $workbook.Sheets.add()
$s5.name = "inactive User"
$cells = $s5.Cells
$s5.range("C1:C1").font.bold = "true"
$s5.range("C1:C1").font.size = 18
$s5.range("C1:C1").cells = "List of Inactive User Acccounts"
$s5.range("A3:A3").cells = "Name"
$s5.range("A3:A3").font.bold = "true"
$row5 = 3
$col5 = 1
Foreach ( $Us in $inacUser) {
	$row5++
	$col5 = 1
	$cells.item($Row5, $col5) = $Us.Name
	$col5++
}
$s5.range("A3:A3").EntireColumn.autofit() | out-Null


# get sheet and update sheet name
$s6 = $workbook.Sheets.add()
$s6.name = "Report Information"

# Put user information on Sheet - 1
$s6.range("D7:D7").cells = "Title:"
$s6.range("D7:D7").font.bold = "true"
$s6.range("E7:E7").cells = "Active Directory Report"
$s6.range("D8:D8").font.bold = "true"
$s6.range("D8:D8").cells = "Generated By:"
$s6.range("E8:E8").cells = "$env:username"
$s6.range("D9:D9").font.bold = "true"
$s6.range("D9:D9").cells = "Generated Date:"
$s6.range("E9:E9").cells = $date
$s6.range("D7:D9").EntireColumn.autofit() | out-Null
#Saving File
"`n"
write-Host "Saving file in $env:userprofile\desktop"
$workbook.SaveAs("$env:userprofile\desktop\ActiveDirectoryReport.xlsx")

## End of the script...

############################################# a m a n   D |
