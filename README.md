# hMailServer-Limit-Outgoing-Messages

Limit Daily Outgoing Messages on hMailServer
   _and_
Require "It's Really Me" after inactivity period


Two projects in one.

Limit Daily Outgoing Messages:
* Tail AWStats log and count outgoing messages
* Update database with daily message count per user
* If user sends more than N messages in a day, disable account and force password change
* Enable account after user successfully changes strong password
* All communication with user via SMS while account is disabled

Inactivity Based Two Factor Auth
* User logons are counted (dated)
* If last logon more than N days in the past, disable account and require user to prove identity
* Proof of identity is simple response to SMS: UNLOCK
* All communication with user via SMS while account is disabled


# System Requirements
- Working hMailServer (Email)
- Working Gammu (SMS)


# Instructions
