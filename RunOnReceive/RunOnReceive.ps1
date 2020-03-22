<#

.SYNOPSIS
	Gammu RunOnReceive

.DESCRIPTION
	Script to direct Gammu RunOnReceive to appropriate actions

.FUNCTIONALITY
	1) Receives Gammu database message ID from RunOnReceive.bat
	2) Retrieve sender number and message from database
	3) Direct sender number and message to appropriate script

.PARAMETER ID
	Specifies the gammu database inbox ID number. Used for retrieval of sender number and message.
	
.NOTES
	Database variables and function are for GAMMU database only!!! (hMailServer database variables and function separately located in pwCommon.ps1)

.EXAMPLE


#>

Param([string]$ID)


<###   GAMMU MYSQL VARIABLES   ###>
$SQLAdminUserName = 'gammu'
$SQLAdminPassword = 'supersecretpassword'
$SQLDatabase      = 'gammu'
$SQLHost          = '127.0.0.1'
$SQLPort          = 3306
$SQLSSL           = 'none'

<#  Gammu Database Function  #>
Function MySQLQuery($Query) {
	$Today = (Get-Date).ToString("yyyyMMdd")
	$DBErrorLog = "$PSScriptRoot\$Today-DBError.log"
	$ConnectionString = "server=" + $SQLHost + ";port=" + $SQLPort + ";uid=" + $SQLAdminUserName + ";pwd=" + $SQLAdminPassword + ";database=" + $SQLDatabase + ";SslMode=" + $SQLSSL + ";"
	Try {
		[void][System.Reflection.Assembly]::LoadWithPartialName("MySql.Data")
		$Connection = New-Object MySql.Data.MySqlClient.MySqlConnection
		$Connection.ConnectionString = $ConnectionString
		$Connection.Open()
		$Command = New-Object MySql.Data.MySqlClient.MySqlCommand($Query, $Connection)
		$DataAdapter = New-Object MySql.Data.MySqlClient.MySqlDataAdapter($Command)
		$DataSet = New-Object System.Data.DataSet
		$RecordCount = $dataAdapter.Fill($dataSet, "data")
		$DataSet.Tables[0]
	}
	Catch {
		Write-Output "$((get-date).ToString(`"yy/MM/dd HH:mm:ss.ff`")) : ERROR : Unable to run query : $query `n$Error[0]" | Out-File $DBErrorLog -append
	}
	Finally {
		$Connection.Close()
	}
}

<#  Get message from database  #>
$Query = "SELECT TextDecoded, SenderNumber FROM inbox WHERE ID = '$ID'"
MySQLQuery $Query | ForEach {
	$rorNum = $_.SenderNumber
	$rorMsg = $_.TextDecoded
}

If ($rorMsg -match 'pw[\s](change|mine|new|random)'){& "$PSScriptRoot\pwChange.ps1" -rorNum $rorNum -rorMsg $rorMsg}
ElseIf ($rorMsg -match 'unlock'){& "$PSScriptRoot\hMSAccountUnlock.ps1" -rorNum $rorNum -rorMsg $rorMsg}
Else { exit }