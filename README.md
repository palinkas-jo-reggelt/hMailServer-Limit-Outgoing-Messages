# hMailServer-Limit-Outgoing-Messages

Limit Daily Outgoing Messages on hMailServer
   *and*
Require "It's Really Me" after inactivity period


Two projects in one.

**Limit Daily Outgoing Messages:**
* Tail AWStats log and count outgoing messages
* Update database with daily message count per user
* If user sends more than N messages in a day, disable account and force password change
* Enable account after user successfully changes strong password
* All communication with user via SMS while account is disabled

**Inactivity Based Two Factor Auth**
* User logons are counted (dated)
* If last logon more than N days in the past, disable account and require user to prove identity
* Proof of identity is simple response to SMS: UNLOCK
* All communication with user via SMS while account is disabled


# System Requirements
- Working hMailServer (Email) 5.7.0 OR one of RvdH's custom builds with OnClientLogon
- Working Gammu (SMS) with functional gammu-smsd-inject AND configured RunOnReceive
- Gammu and hMailServer running on MySQL (connection strings and queries are for MySQL only)


# Instructions

**For Gammu:**

1) Place powershell scripts in your runonrecieve folder, or create one. I've included RunOnReceive.bat and RunOnReceive.ps1 if you have not configured Gammu runonrecieve. You must configure smsdrc with the runonreceive path to RunOnReceive.bat. If you already have a working runonreceive with your own scripts, modify them per the included RunOnReceive.ps1.
2) Change the path in RunOnReceive.bat
3) Change the user variables in RunOnReceive.ps1
4) Change the user variables in pwCommon.ps1


**For hMailServer:**

1) Copy the contents of EventHandlers.vbs into your hMailServer EventHandlers.vbs (default location: C:\Program Files (x86)\hMailServer\Events).
2) In Sub GetTwoFactorInfo, change the mysql connection string according to your variables.
3) In Sub OnClientLogon, read the notes and change the variables according to your needs.
4) If you DON'T WANT to use the inactivity two factor portion of the project, simply skip the above (do not modify EventHandlers.vbs).


**To Setup Database:**

1) After updating the user variables, run hmsLimitOutgoing-DB-Setup.ps1. This will create table hm_accounts_mobile and will also query existing hm_accounts for all user accounts and export them to Accounts.csv.
2) Manually update Accounts.csv to include mobile numbers for each account. If the account is not a real person's account, leave it 0. The two-factor should only be used for real people that can respond to SMS, not machine accounts for scripts and scanners, etc.
3) Run hmsLimitOutgoing-DB-Setup.ps1 again to update the hm_accounts_mobile with the data you manually entered.


**For Tailing AWStats Log:**

Create a scheduled task to run hmsLimitOutgoing.ps1 at startup !!!AND!!! at 12:01 AM daily (one task, two triggers). Script runs 27/7.


**For Web Admin:**

Copy www folder into php accessible webserver and change variables in config.php. Warning: uses hMailServer COM: you must extension=php_com_dotnet.dll in php.ini in order to enable/disable accounts.