<#

.SYNOPSIS
	Message to kill hmsLimitOutgoing.ps1 script

.DESCRIPTION
	Last message of the day, sent in order to kill the tail loop.

.FUNCTIONALITY
	Sends email message to admin. Tail function will trigger IF CURRENT TIME > FINISH TIME statement unless a message comes in to trigger it.

.NOTES
	Run from task scheduler:
		- At 23:57:10 Daily
	
.EXAMPLE


#>

<###  User Variables  ###>
$FromAddress      = 'notifier.account@gmail.com'
$Recipient        = 'admin@mydomain.com'
$SMTPServer       = 'smtp.gmail.com'
$SMTPAuthUser     = 'notifier.account@gmail.com'
$SMTPAuthPass     = 'supersecretpassword'
$SMTPPort         = 587
$SSL              = 'True'

<#  Include required files  #>
Try {
	.("$PSScriptRoot\pwCommon.ps1")
}
Catch {
	Write-Output "$((get-date).ToString(`"yy/MM/dd HH:mm:ss.ff`")) : ERROR : Unable to load supporting PowerShell Scripts : $query `n$Error[0]" | out-file "$PSScriptRoot\PSError.log" -append
}

Function EmailResults($Msg) {
	$Subject = "Time to kill Limit Outgoing today" 
	$Body = $Msg
	$Message = New-Object System.Net.Mail.Mailmessage $FromAddress, $Recipient, $Subject, $Body
	$SMTP = New-Object System.Net.Mail.SMTPClient $SMTPServer,$SMTPPort
	$SMTP.EnableSsl = [System.Convert]::ToBoolean($SSL)
	$SMTP.Credentials = New-Object System.Net.NetworkCredential($SMTPAuthUser, $SMTPAuthPass); 
	$SMTP.Send($Message)
}

EmailResults "Time to finish the hmsLimitOutgoing.ps1 script"