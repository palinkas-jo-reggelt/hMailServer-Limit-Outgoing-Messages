<#

.SYNOPSIS
	Setup Database for hMailServer Limit Outgoing Messages / Two Factor Project

.DESCRIPTION
	Setup Database for hMailServer Limit Outgoing Messages / Two Factor Project

.FUNCTIONALITY
	1) Run once from powershell console to setup database, create scheduled task and export users to csv (script creates Accounts.csv located in same folder as script)
	2) Manually edit Accounts.csv to add mobile numbers
	3) Run again to fill hm_accounts_mobile with account and mobilenumber data from Accounts.csv

.NOTES
	Column "lastlogontime" gets filled with current datetime so all users don't get blasted with requests to unlock account the next time they log in.
	
.EXAMPLE


#>

<#  Include required files  #>
Try {
	.("$PSScriptRoot\pwCommon.ps1")
}
Catch {
	Write-Output "$((get-date).ToString(`"yy/MM/dd HH:mm:ss.ff`")) : ERROR : Unable to load supporting PowerShell Scripts : $query `n$Error[0]" | out-file "$PSScriptRoot\PSError.log" -append
}

$AccountsFile = "$PSScriptRoot\Accounts.csv"

<#  If Accounts.csv doesn't exist, that means script hasn't run yet, so setup database and create/fill Accounts.csv with account data  #>
If (-not(Test-Path $AccountsFile)){

	$Query = "
		CREATE TABLE IF NOT EXISTS hm_accounts_mobile (
		  account varchar(192) NOT NULL,
		  mobilenumber varchar(10) NOT NULL,
		  accountlock int(1) NOT NULL,
		  accountdisabled int(1) NOT NULL,
		  lastlocktime datetime NOT NULL DEFAULT '1969-12-31 23:59:59',
		  lastlogontime datetime NOT NULL DEFAULT '1969-12-31 23:59:59',
		  lastmessagetime datetime NOT NULL DEFAULT '1969-12-31 23:59:59',
		  messagecount int(3) NOT NULL,
		  initpw int(1) NOT NULL,
		  PRIMARY KEY (account)
		) ENGINE=InnoDB DEFAULT CHARSET=utf8;
		COMMIT;
	"
	MySQLQuery $Query

	<#  Create header in Accounts.csv  #>
	Write-Output "account,mobilenumber" | Out-File $AccountsFile -Append

	<#  Fill account data into Accounts.csv  #>
	$Query = "SELECT accountaddress FROM hm_accounts;"
	MySQLQuery $Query | ForEach {
		$Account = $_.accountaddress
		Write-Output "$Account," | Out-File $AccountsFile -Append
	}

<#  If Accounts.csv exists, then database is created and presumeably the csv file has been edited to include mobile numbers  #>
} Else {

	<#  Fill hm_accounts_mobile with data from csv  #>
	$ImportMobileNumbers = Import-CSV -Path $AccountsFile -Delimiter "," -Header account, mobilenumber
	$ImportMobileNumbers | ForEach {
		$Account = $_.account
		$MobileNumber = $_.mobilenumber
		If ($Account -notmatch "account"){
			$Query = "INSERT INTO hm_accounts_mobile (account,mobilenumber,lastlogontime) VALUES ('$Account','$MobileNumber',NOW());"
			MySQLQuery $Query
		}
	}
}