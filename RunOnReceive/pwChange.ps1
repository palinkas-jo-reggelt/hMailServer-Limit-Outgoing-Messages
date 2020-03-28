<#

.SYNOPSIS
	hMailServer SMS Password Changer

.DESCRIPTION
	Change your hMailServer account password via SMS

.FUNCTIONALITY
	1) Initiates password change by SMS command
	2) Option to create personalized password or have a random one created for you
	3) Enforces strong passwords
	4) Detailed instructions given at every event

.PARAMETER rorNum
	Specifies the SMS mobile number. Used to validate account and for returning confirmation.
	
.PARAMETER rorMsg
	Specifies the SMS message. 
	
.NOTES
	Documentation available at PW change website.

.EXAMPLE
	Initiate password change via SMS:
		pw change

	Re-Initiation of password change via SMS when multiple accounts are associated with a single mobile number:
		pw change <email@address.com>

	Request random password assigned via SMS:
		pw random
	
	Request personalized password via SMS:
		pw mine

	Dictate new password via SMS:
		pw new <new-password>
#>

Param(
  [ValidatePattern('^\+\d{11}$|^\d{10}$')]
  [string]$rorNum,
  [ValidatePattern('pw[\s](change|mine|new|random)')]
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

<#  RegEx  #>
$RegexEmail = "([A-Za-z0-9!.#$%&'*+\/=?^_`{|}~-]+@([A-Za-z0-9-]{2,63}\.){1,10}[A-Za-z0-9-]{2,12})"
[regex]$RegexMultiMatch = "([pP][wW]\s[cC][hH][aA][nN][gG][eE]\s)$RegexEmail"

<#	If reply contains "PW CHANGE <emailaddress>, use the email address in the password changer   #>
If ($rorMsg -match $RegexMultiMatch){
	$PWChangeMsg = ($rorMsg).Trim()
	$EmailFromMsg = $PWChangeMsg.Split(" ")[2]

	<#  Validate email address  #>
	$Query = "SELECT COUNT(account) AS countaccount FROM hm_accounts_mobile WHERE account = '$EmailFromMsg';"
	MySQLQuery $Query | ForEach {
		$CountAccount = $_.countaccount
		Write-Host $CountAccount
	}

	<#  If only one address matches, set email and send initial message  #>
	If ($CountAccount -eq 1){

		<#  Set email  #>
		$Email = $EmailFromMsg
		$Query = "UPDATE hm_accounts_mobile SET initpw = 1 WHERE account = '$Email';"
		MySQLQuery $Query

		<#  Send first set of instructions  #>
		$Msg = "You have requested a new password for $email. Refer to $PWURL for instructions. You can make your own password or I can create a random one. Reply PW MINE to create your own or PW RANDOM if you want me to create it for you."
		SendSMS $Num $Msg

	} Else {
		<#  If 0 or multiple addresses found, kick it back  #>
		$Msg = "The email address you provided cannot be found. Please check the spelling and try again. Reply: PW CHANGE email@domain.com"
	}

} ElseIf ($rorMsg -match "([pP][wW]\s[cC][hH][aA][nN][gG][eE])(\s+)?"){

	<#  Count matches to email from number  #>
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

			<#  Send first set of instructions  #>
			$Msg = "You have requested a new password for $email. Refer to $PWURL for instructions. You can make your own password or I can create a random one. Reply PW MINE to create your own or PW RANDOM if you want me to create it for you."
			SendSMS $Num $Msg
		}

	} Else {
		<#  If count > 1, send message with instructions  #>
		$Msg = "You have multiple accounts associated with your mobile number. Reply with the account you want to change: PW CHANGE username@domain.com"
		SendSMS $Num $Msg
	}
}

<#  If REPLY = MINE  #>
If ($rorMsg -match "([pP][wW]\s[mM][iI][nN][eE])(\s+)?"){

	<#  Send instructions for personalized password creation  #>
	$Msg = "You have chosen to create your own password. Your password must be a minimum of 12 characters and contain at least one of the following characters !#$%&*+,-.:=?^_~ as well as at least one capital letter, one lowercase letter and one numeric digit. Reply PW NEW followed by your chosen password."
	SendSMS $Num $Msg
}

<#  If REPLY = NEW  #>
If ($rorMsg -match "([pP][wW]\s[nN][eE][wW])(\s+)?"){
	$Email = GetAccount $Num
	$Domain = ($Email).Split("@")[1]

	<#  Trim incoming message to leave only password as string  #>
	$Password = $rorMsg -replace ('pw\snew\s','')
	$Password = $Password -replace ('\s$','')

	<#  Test personalized password for validation and deny if validation fails  #>
	If(-not(TestPassword $Password)){
		$Msg = "Your password ($Password) did not pass validation. See $PWURL for reference. Your password must be a minimum of 12 characters and contain at least one of the following characters !#$%&*+,-.:=?^_~ as well as at least one capital letter, one lowercase letter and one number. Reply PW NEW followed by your chosen password."
		SendSMS $Num $Msg
	}

	<#  If validation successful, change password and send confirmation message  #>
	Else {

		<#  First, change password  #>
		Change-Password $Email $Password

		<#  If password change successful, send confirmation message  #>
		If ($((($hMS.Domains.ItemByName($Domain)).Accounts.ItemByAddress($Email)).ValidatePassword($Password)) -eq $True){
			$Msg = "Your new password ($Password) for $Email was accepted. Please go to $WebMailURL to log into your email."
			SendSMS $Num $Msg

			<#  If account disabled, enable it now that password has changed  #>
			If (-not(IsAccountEnabled $Email)){

				<#  Enable account  #>
				EnableAccount $Email

				<#  Send admin confirmation message  #>
				$AdminMsg = "User $Account successfully changed password and unlocked account."
				SendSMS $AdminNumber $AdminMsg

				<#  Reset message count so it doesn't repeatedly trip account disable  #>
				$Query = "UPDATE hm_accounts_mobile SET messagecount = 0 WHERE account = '$Email';"
				MySQLQuery $Query
			}
			<#  Reset initpw so we don't confuse the correct account/mobilenumber combination next time we need it  #>
			$Query = "UPDATE hm_accounts_mobile SET initpw = 0 WHERE account = '$Email';"
			MySQLQuery $Query
		}

		Else {
			<#  On error, send error message  #>
			$Msg = "Something went wrong. Please contact the administrator."
			SendSMS $Num $Msg

			<#  On error, notify admin  #>
			$AdminMsg = "ERROR - Something went wrong with $Account password change."
			SendSMS $AdminNumber $AdminMsg
			Exit
		}
	}
}

<#  If REPLY = RANDOM  #>
If ($rorMsg -match "([pP][wW]\s[rR][aA][nN][dD][oO][mM])(\s+)?"){
	$Email = GetAccount $Num
	$Domain = ($Email).Split("@")[1]

	<#  Create random 12 char password and use it to change password  #>
	$Password = Create-Password 12 ULNS "OLIoli01"
	Change-Password $Email $Password

	<#  If password change successful, send confirmation message  #>
	If ($((($hMS.Domains.ItemByName($Domain)).Accounts.ItemByAddress($Email)).ValidatePassword($Password)) -eq $True){
		$Msg = "Your new password is $password for the account $Email. Please go to $WebMailURL to log into your email."
		SendSMS $Num $Msg

		<#  If account disabled, enable it now that password has changed  #>
		If (-not(IsAccountEnabled $Email)){

			<#  Enable account  #>
			EnableAccount $Email

			<#  Send admin confirmation message  #>
			$AdminMsg = "User $Account successfully changed password and unlocked account."
			SendSMS $AdminNumber $AdminMsg

			<#  Reset message count so it doesn't repeatedly trip account disable  #>
			$Query = "UPDATE hm_accounts_mobile SET messagecount = 0 WHERE account = '$Email';"
			MySQLQuery $Query
		}
		<#  Reset initpw so we don't confuse the correct account/mobilenumber combination next time we need it  #>
		$Query = "UPDATE hm_accounts_mobile SET initpw = 0 WHERE account = '$Email';"
		MySQLQuery $Query
	}

	Else {
		<#  On error, send error message  #>
		$Msg = "Something went wrong. Please contact the administrator."
		SendSMS $Num $Msg

		<#  On error, notify admin  #>
		$AdminMsg = "ERROR - Something went wrong with $Account password change."
		SendSMS $AdminNumber $AdminMsg
		Exit
	}
}