<#

.SYNOPSIS
	Tail hMailServer AWStats Log & Count Outgoing Messages

.DESCRIPTION
	Tail hMailServer AWStats Log & Count Outgoing Messages

.FUNCTIONALITY
	Tails AWStats log, updates database with daily message count.

.NOTES
	Run from task scheduler with TWO triggers:
		- At Startup
		- At 12:01 AM Daily
	
.EXAMPLE


#>

<#  Include required files  #>
Try {
	.("$PSScriptRoot\pwCommon.ps1")
}
Catch {
	Write-Output "$((get-date).ToString(`"yy/MM/dd HH:mm:ss.ff`")) : ERROR : Unable to load supporting PowerShell Scripts : $query `n$Error[0]" | out-file "$PSScriptRoot\PSError.log" -append
}

<#	Check to see if hMailServer is running. If not, quit. MySQL is a dependency of hMailServer service so you're actually checking both.   #>
<#	Prevents scheduled task failures at bootup.   #>
Do {
	If ((get-service hMailServer).Status -ne 'Running') { 
		$Running = "NO"
		Start-Sleep -seconds 30
	} Else { 
		$Running = "YES" 
	}
} Until ($Running = "YES")

<#	RegEx to find email address in a string   #>
[regex]$RegexEmail = "[A-Za-z0-9!.#$%&'*+\/=?^_`{|}~-]+@([A-Za-z0-9-]{2,63}\.){1,10}[A-Za-z0-9-]{2,12}"

<#	Tail log and convert log lines to objects   #>
Get-Content "$hMSLogFolder\hmailserver_awstats.log" -Wait -Tail 1 | ConvertFrom-String -Delimiter "`t" -PropertyNames TimeStamp, Sender, Recipient, ConnectionSender, ConnectionRecipient, Protocol, QuestionMark, StatusCode, MessageSize | ForEach {

	$Sender = $_.Sender
	$MsgTimeStamp = $_.TimeStamp

	<#	Clear out variables in loop  #>
	$Account = $UpdateQuery = $Query = $Account = $MobileNumber = $LastMessageTime = $MessageCount = $Msg = $NULL

	<#  Check if sender is local by checking if hMailServer user exists  #>
	$Query = "SELECT account, mobilenumber FROM hm_accounts_mobile WHERE account = '$Sender';"
	MySQLQuery $Query | ForEach {
		$Account = $_.account
		$MobileNumber = $_.mobilenumber
	}

	<#  If user local, get last message time  #>
	If ($Sender -match $Account){
		$Query = "SELECT lastmessagetime FROM hm_accounts_mobile WHERE account = '$Account';"
		MySQLQuery $Query | ForEach {
			$LastMessageTime = Get-Date $_.lastmessagetime
		}
		
		<#  If last message today, then update count = existing count + 1; otherwise this is the first message of the day  #>
		If ($LastMessageTime -lt ([datetime]::Today)){
			$UpdateQuery = "UPDATE hm_accounts_mobile SET lastmessagetime = NOW(), messagecount = 1 WHERE account = '$Account';"
		} Else {
			$UpdateQuery = "UPDATE hm_accounts_mobile SET lastmessagetime = NOW(), messagecount = (messagecount + 1) WHERE account = '$Account';"
		}
		MySQLQuery $UpdateQuery

		<#  Get total count for user  #>
		$Query = "SELECT messagecount FROM hm_accounts_mobile WHERE account = '$Account';"
		MySQLQuery $Query | ForEach {
			$MessageCount = $_.messagecount
		}

		<#  If message count exceeded, disable account and send SMS notification requiring password change  #>
		If ($MessageCount -gt $MsgLimit){

			<#  Only send notification to user if account has mobile number  #>
			If ($MobileNumber -ne 0){

				<#  Disable account  #>
				DisableAccount $Account

				<#  Send notification  #>
				$Msg = "Security notice from $(((Get-Culture).TextInfo).ToTitleCase(($Account).Split('@')[1])) Mail Server: Your account ($Account) has exceeded $MsgLimit outgoing messages today and has been disabled to prevent abuse. In order to enable your account you are required to change your password. Reply PW CHANGE to initiate process."
				SendSMS $MobileNumber $Msg
			}

			<#  Notify admin  #>
			$AdminMsg = "Outgoing message limit exceeded for $Account - account disabled."
			SendSMS $AdminNumber $AdminMsg
		}
	}
	<#	Quit script at 23:57 in order to load next day's log (initiated by scheduled task at 00:01)  #>
	If ((Get-Date -format HH:mm) -gt "23:56") { Exit }
}