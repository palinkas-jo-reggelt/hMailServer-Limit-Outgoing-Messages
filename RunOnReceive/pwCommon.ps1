<#

.SYNOPSIS
	hMailServer SMS Password Changer

.DESCRIPTION
	Support functions and data for SMS Password Changer

.FUNCTIONALITY


.PARAMETER ID
	Specifies the gammu database inbox ID number. Used for retrieval of sender number and message.
	
.NOTES
	Fill User & MySQL variables below

.EXAMPLE


#>

<###   USER VARIABLES   ###>
$hMSAdminPass = "b!gH0rny69"                                #<-- hMailServer Administrator Password
$hMSLogFolder = "C:\Program Files (x86)\hMailServer\Logs"   #<-- hMailServer Log Folder
$MsgLimit = 100                                             #<-- Outgoing daily message limit per user
$PWURL = "https://wap.dynu.net/pw"                          #<-- URL of password changer website
$WebMailURL = "https://wap.dynu.net"                        #<-- URL of webmail
$AdminNumber = "9173286699"                                 #<-- Mobile number of system admin for notifications

<###   MYSQL VARIABLES   ###>
$SQLAdminUserName = 'hmailserver'
$SQLAdminPassword = 'SSnGLBs8XswL2r0h'
$SQLDatabase      = 'hmailserver'
$SQLHost          = '127.0.0.1'
$SQLPort          = 3306
$SQLSSL           = 'none'

<#  Database Function  #>
Function MySQLQuery($Query) {
	$Today = (Get-Date).ToString("yyyyMMdd")
	$DBErrorLog = "$PSScriptRoot\$Today-Limit-Outgoing-DBError.log"
	$ConnectionString = "server=" + $SQLHost + ";port=" + $SQLPort + ";uid=" + $SQLAdminUserName + ";pwd=" + $SQLAdminPassword + ";database=" + $SQLDatabase + ";SslMode=" + $SQLSSL + ";"
	Try {
		[void][System.Reflection.Assembly]::LoadWithPartialName("MySql.Data")
		$Connection = New-Object MySql.Data.MySqlClient.MySqlConnection
		$Connection.ConnectionString = $ConnectionString
		$Connection.Open()
		$Command = New-Object MySql.Data.MySqlClient.MySqlCommand($Query, $Connection)
		$DataAdapter = New-Object MySql.Data.MySqlClient.MySqlDataAdapter($Command)
		$DataSet = New-Object System.Data.DataSet
		$RecordCount = $dataAdapter.Fill($DataSet, "data")
		$DataSet.Tables[0]
	}
	Catch {
		Write-Output "$((get-date).ToString(`"yy/MM/dd HH:mm:ss.ff`")) : ERROR : Unable to run query : $query `n$Error[0]" | Out-File $DBErrorLog -append
	}
	Finally {
		$Connection.Close()
	}
}

<#  Send SMS Message  #>
Function SendSMS($Num, $Msg) {
	[int]$len = ([convert]::ToInt32(($Msg.length), 10))
	& cmd.exe /c gammu-smsd-inject -c C:\gammu\bin\smsdrc TEXT $Num -len $len -text $Msg
}

<#  Password Validation  #>
Function TestPassword ([string]$password){
	[bool]($password|
		where-object {$_.length -gt 11} |
		where-object {$_ -match '[a-z]'}|
		where-object {$_ -match '[A-Z]'}|
		where-object {$_ -match '[0-9]'}|
		where-object {$_ -match '[!#$%&*+,-.:=?^_~]'}|
		where-object {$_ -notmatch '[\s\n]'}|
		where-object {$_ -match '[^a-zA-Z0-9]'}
	)
}

<#  Authenticate hMailServer COM  #>
$hMS = (New-Object -COMObject hMailServer.Application)
$hMS.Authenticate("Administrator", $hMSAdminPass) | Out-Null

<#  Change Password Function  #>
Function Change-Password ($Email, $Password){
	$Domain = $Email.split('@')[1]
	$hMSAccount = ($hMS.Domains.ItemByName($Domain)).Accounts.ItemByAddress($Email)
	$hMSAccount.Password = $Password
	$hMSAccount.Save()
}

<#  Disable Account Function  #>
Function DisableAccount($Account){
	<#  Disable account  #>
	$Domain = ($Account).Split("@")[1]
	$hMSAccountStatus = ($hMS.Domains.ItemByName($Domain)).Accounts.ItemByAddress($Account)
	$hMSAccountStatus.Active = $False
	$hMSAccountStatus.Save()
	
	<#  Update accountdisabled in database  #>
	$UpdateQuery = "UPDATE hm_accounts_mobile SET accountdisabled = 1 WHERE account = '$Account';"
	MySQLQuery $UpdateQuery
}

<#  Enable Account Function  #>
Function EnableAccount($Account){
	<#  Enable account  #>
	$Domain = ($Account).Split("@")[1]
	$hMSAccountStatus = ($hMS.Domains.ItemByName($Domain)).Accounts.ItemByAddress($Account)
	$hMSAccountStatus.Active = $True
	$hMSAccountStatus.Save()

	<#  Update accountdisabled in database  #>
	$UpdateQuery = "UPDATE hm_accounts_mobile SET accountdisabled = 0 WHERE account = '$Account';"
	MySQLQuery $UpdateQuery
}

<#  Is Account Enabled Function  #>
Function IsAccountEnabled($Account){
	$Status = $False
	$Domain = ($Account).Split("@")[1]
	$hMSAccountStatus = ($hMS.Domains.ItemByName($Domain)).Accounts.ItemByAddress($Account)
	If ($hMSAccountStatus.Active -eq $True){
		$Status = $True
	}
	Return $Status
}

<#  Random Password Generator Function  #>
Function MakeUp-String([Int]$Size = 12, [Char[]]$CharSets = "ULNS", [Char[]]$Exclude) {
    $Chars = @(); $TokenSet = @()
    If (!$TokenSets) {$Global:TokenSets = @{
        U = [Char[]]'ABCDEFGHIJKLMNOPQRSTUVWXYZ'               #Upper case
        L = [Char[]]'abcdefghijklmnopqrstuvwxyz'               #Lower case
        N = [Char[]]'0123456789'                               #Numerals
        S = [Char[]]'!#$%&*+,-.:=?^_~'                         #Symbols
    }}
    $CharSets | ForEach {
        $Tokens = $TokenSets."$_" | ForEach {If ($Exclude -cNotContains $_) {$_}}
        If ($Tokens) {
            $TokensSet += $Tokens
            If ($_ -cle [Char]"Z") {$Chars += $Tokens | Get-Random}             #Character sets defined in upper case are mandatory
        }
    }
    While ($Chars.Count -lt $Size) {$Chars += $TokensSet | Get-Random}
    ($Chars | Sort-Object {Get-Random}) -Join ""                                #Mix the (mandatory) characters and output string
}; Set-Alias Create-Password MakeUp-String -Description "Generate a random string (password)"

<#  Get account from mobile number  #>
Function GetAccount($Num){
	$Email = ""

	$Query = "SELECT COUNT(account) AS countaccount FROM hm_accounts_mobile WHERE mobilenumber = '$Num';"
	MySQLQuery $Query | ForEach {
		$CountAccount = $_.countaccount
	}

	<#  If count = 1, use that address  #>
	If ($CountAccount -eq 1){
		<#  Match email to number  #>
		$Query = "SELECT account FROM hm_accounts_mobile WHERE mobilenumber = '$Num';"
		MySQLQuery $Query | ForEach {
			$Email = $_.account
		}
	} Else {
		$Query = "SELECT account FROM hm_accounts_mobile WHERE mobilenumber = '$Num' AND initpw = 1"
		MySQLQuery $Query | ForEach {
			$Email = $_.account
		}
	}
	
	Return $Email
}