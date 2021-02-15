<?php

/*	Site Logon Variables 
	Username and password to allow access to site
*/

$user_name = 'admin';
$pass_word = 'supersecretpassword';

// Cookie Duration in days
$cookie_duration = 90; 


/*	Database Variables 

	MySQL only!
	
	'driver' = connection type
	
		For MySQL use driver = 'mysql'
		For ODBC  use driver = 'odbc'
		
		* When opting for ODBC use correct DSN! *
		* Example: "MariaDB ODBC 3.0 Driver"    *
		* Exact spelling is critical!           *
	
*/

$Database = array (
	'host'        => 'localhost',
	'username'    => 'hmailserver',
	'password'    => 'supersecretpassword',
	'dbname'      => 'hmailserver',
	'driver'      => 'mysql',
	'port'        => '3306',
	'dsn'         => 'MariaDB ODBC 3.1 Driver'
);


/*  hMailServer COM Authentication 
	Password for hMailServer "Administrator"
*/

$hMSAdminPass = "supersecretpassword";

?>