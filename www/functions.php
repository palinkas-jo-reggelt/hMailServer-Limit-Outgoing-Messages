<?php

	If ($Database['driver'] == 'mysql') {
		$pdo = new PDO("mysql:host=".$Database['host'].";port=".$Database['port'].";dbname=".$Database['dbname'], $Database['username'], $Database['password']);
	} ElseIf ($Database['driver'] == 'mssql') {
		$pdo = new PDO("sqlsrv:Server=".$Database['host'].",".$Database['port'].";Database=".$Database['dbname'], $Database['username'], $Database['password']);
	} ElseIf ($Database['driver'] == 'odbc') {
		$pdo = new PDO("odbc:Driver={".$Database['dsn']."};Server=".$Database['host'].";Port=".$Database['port'].";Database=".$Database['dbname'].";User=".$Database['username'].";Password=".$Database['password'].";");
	} Else {
		echo "Configuration Error - No database driver specified";
	}

	Function displayMobileNumber($mobilenumber){
		if (preg_match('/^(\d{3})(\d{3})(\d{4})$/', $mobilenumber,  $matches )){
			$result = '('.$matches[1].') '.$matches[2].'-'.$matches[3];
		} else {
			$result = $mobilenumber;
		}
		return $result;
	}

	Function disableAccount($account){
		global $hMSAdminPass;
		$hMS = new COM("hMailServer.Application");
		$hMS->Authenticate("Administrator", $hMSAdminPass);
		$Splitter = split ("@", $account);
		$Domain = $Splitter[1];
		$hMSDomainStatus = $hMS->Domains->ItemByName($Domain);
		$hMSAccountStatus = $hMSDomainStatus->Accounts->ItemByAddress($account);
		$hMSAccountStatus->Active="False";
		$hMSAccountStatus->Save();
	}

	Function enableAccount($account){
		global $hMSAdminPass;
		$hMS = new COM("hMailServer.Application");
		$hMS->Authenticate("Administrator", $hMSAdminPass);
		$Splitter = split ("@", $account);
		$Domain = $Splitter[1];
		$hMSDomainStatus = $hMS->Domains->ItemByName($Domain);
		$hMSAccountStatus = $hMSDomainStatus->Accounts->ItemByAddress($account);
		$hMSAccountStatus->Active="True";
		$hMSAccountStatus->Save();
	}

?>
