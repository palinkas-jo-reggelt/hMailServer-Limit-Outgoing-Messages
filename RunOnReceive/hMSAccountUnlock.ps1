<#

.SYNOPSIS
	hMailServer Account Unlock

.DESCRIPTION
	Unlock hMailServer email account via SMS after lock due to inactivity.

.FUNCTIONALITY
	1) Recieves UNLOCK command by SMS
	2) Removes disconnect switch from account

.PARAMETER rorNum
	Specifies the SMS mobile number. 
	
.PARAMETER rorMsg
	Specifies the SMS message. 
	
.NOTES


.EXAMPLE


#>

Param(
	[ValidatePattern('^\+\d{11}$|^\d{10}$')]
	[string]$rorNum,
	[ValidatePattern('unlock')]
	[string]$rorMsg
)

<#  Include required files  #>
Try {
	.("$PSScriptRoot\pwCommon.ps1")
}
Catch {
	Write-Output "$((get-date).ToString(`"yy/MM/dd HH:mm:ss.ff`")) : ERROR : Unable to load supporting PowerShell Scripts : $query `n$Error[0]" | out-file "$PSScriptRoot\PSError.log" -append
}

<#  Set script variables from parameters  #>
[regex]$RegExNum = "[0-9]{10}$"
$Num = ($RegExNum.Matches($rorNum)).Value

<#  Get username from mobile number  #>
$Query = "SELECT account, accountlock FROM hm_accounts_mobile WHERE mobilenumber = '$Num';"
MySQLQuery $Query | ForEach {
	$Account = $_.account
	$Lock = $_.accountlock
	
	If ($Lock -eq 1){
		<#  Revert switch back to 0 to unlock account  #>
		$Query = "UPDATE hm_accounts_mobile SET accountlock = 0 WHERE account = '$Account';"
		MySQLQuery $Query

		<#  Send account unlocked notification message  #>
		$Msg = "Your account ($Account) has been unlocked. You may now login."
		SendSMS $Num $Msg
		
		<#  Reset last logon to NOW  #>
		$Query = "UPDATE hm_accounts_mobile SET lastlogontime = NOW() WHERE account = '$Account';"
		MySQLQuery $Query
	}
}