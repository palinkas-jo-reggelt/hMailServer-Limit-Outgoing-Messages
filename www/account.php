<?php
    session_start();
    if(!isset($_SESSION['login'])) {
        header('LOCATION:login.php'); die();
    }
?>

<?php include("head.php") ?>

<?php
	include_once("config.php");
	include_once("functions.php");

	if (isset($_GET['account'])) {$account = $_GET['account'];} else {$account = "";}
	if (isset($_GET['updatemobilenumber'])){
		$updatemobilenumber = $_GET['updatemobilenumber'];
		$pdo->exec("UPDATE hm_accounts_mobile SET mobilenumber=".$updatemobilenumber." WHERE account='".$account."';");
		header("Location: ./account.php?account=".$account);
	}
	if (isset($_GET['updatelastlogontime'])){
		$pdo->exec("UPDATE hm_accounts_mobile SET lastlogontime=NOW() WHERE account='".$account."';");
		header("Location: ./account.php?account=".$account);
	}
	if (isset($_GET['updatemessagecount'])){
		$pdo->exec("UPDATE hm_accounts_mobile SET messagecount=0 WHERE account='".$account."';");
		header("Location: ./account.php?account=".$account);
	}
	if (isset($_GET['enableaccount'])){
		enableAccount($account);
		$pdo->exec("UPDATE hm_accounts_mobile SET accountdisabled=0 WHERE account='".$account."';");
		header("Location: ./account.php?account=".$account);
	}
	if (isset($_GET['disableaccount'])){
		disableAccount($account);
		$pdo->exec("UPDATE hm_accounts_mobile SET accountdisabled=1 WHERE account='".$account."';");
		header("Location: ./account.php?account=".$account);
	}
	if (isset($_GET['unlockaccount'])){
		$pdo->exec("UPDATE hm_accounts_mobile SET accountlock=0, lastlogontime=NOW() WHERE account='".$account."';");
		header("Location: ./account.php?account=".$account);
	}
	if (isset($_GET['lockaccount'])){
		$pdo->exec("UPDATE hm_accounts_mobile SET accountlock=1 WHERE account='".$account."';");
		header("Location: ./account.php?account=".$account);
	}

	echo "<div class='section'>";
	echo "<br><br>";
	echo "<b>Account: ".$account."</b>";
	echo "<br><br>";

	$sql = $pdo->prepare("
		SELECT 
			account, 
			mobilenumber, 
			lastlocktime, 
			lastlogontime, 
			lastmessagetime, 
			messagecount, 
			accountdisabled,
			accountlock,
			initpw
		FROM hm_accounts_mobile 
		WHERE account = '".$account."';
	");
	$sql->execute();
	echo "<table class='section'>";
	while($row = $sql->fetch(PDO::FETCH_ASSOC)){
		echo "<tr>
				<td>Mobile Number:</td>
				<td>".displayMobileNumber($row['mobilenumber'])."</td>
				<td>
					<form action='account.php' method='GET' onsubmit='return confirm(\"Are you sure you want to change the mobile number?\");'>
						<input type='text' size='12' name='updatemobilenumber' placeholder='".$row['mobilenumber']."'>
						<input type='hidden' name='account' value='".$row['account']."'>
						<input type='submit' name='submit' value='Edit' >
					</form>
				</td>
			</tr>";
		echo "<tr>
				<td>Last Lock:</td>
				<td>".$row['lastlocktime']."</td>
				<td>
				</td>
			</tr>";
		echo "<tr>
				<td>Last Logon:</td>
				<td>".$row['lastlogontime']."</td>
				<td>
					<form action='account.php' method='GET' onsubmit='return confirm(\"Are you sure you want to reset last logon time?\");'>
						<input type='submit' name='updatelastlogontime' value='Update to NOW' >
						<input type='hidden' name='account' value='".$row['account']."'>
					</form>
				</td>
			</tr>";
		echo "<tr>
				<td>Last Message:</td>
				<td>".$row['lastmessagetime']."</td>
				</td>
				<td>
			</tr>";
		echo "<tr>
				<td>Message Count:</td>
				<td>".$row['messagecount']."</td>
				<td>
					<form action='account.php' method='GET' onsubmit='return confirm(\"Are you sure you want to reset the message count?\");'>
						<input type='submit' name='updatemessagecount' value='Reset Message Count' >
						<input type='hidden' name='account' value='".$row['account']."'>
					</form>
				</td>
			</tr>";
		if ($row['accountdisabled']==0){$disabledaccount="No";}else{$disabledaccount="Yes";}
		echo "<tr>
				<td>Account Disabled:</td>
				<td>".$disabledaccount."</td>
				<td>
					<form action='account.php' method='GET' onsubmit='return confirm(\"Are you sure you want to enable the account?\");'>
						<input type='hidden' name='account' value='".$row['account']."'>
						<input type='submit' name='enableaccount' value='Enable Account' >
					</form>
					<br>
					<form action='account.php' method='GET' onsubmit='return confirm(\"Are you sure you want to disable the account?\");'>
						<input type='hidden' name='account' value='".$row['account']."'>
						<input type='submit' name='disableaccount' value='Disable Account' >
					</form>
				</td>
			</tr>";
		if ($row['accountlock']==0){$lockedaccount="No";}else{$lockedaccount="Yes";}
		echo "<tr>
				<td>Account Locked:</td>
				<td>".$lockedaccount."</td>
				<td>
					<form action='account.php' method='GET' onsubmit='return confirm(\"Are you sure you want to unlock the account?\");'>
						<input type='hidden' name='account' value='".$row['account']."'>
						<input type='submit' name='unlockaccount' value='Unlock Account' >
					</form>
					<br>
					<form action='account.php' method='GET' onsubmit='return confirm(\"Are you sure you want to lock the account?\");'>
						<input type='hidden' name='account' value='".$row['account']."'>
						<input type='submit' name='lockaccount' value='Lock Account' >
					</form>
				</td>
			</tr>";
		if ($row['initpw']==0){$pwinit="No";}else{$pwinit="Yes";}
		echo "<tr>
				<td>Password Change Initiated:</td>
				<td>".$pwinit."</td>
				</td>
				<td>
			</tr>";
	}
	echo "</table>";

	echo "<br><br>";

	echo "<table>";
	echo "<tr><td><u>Notes</u></td><td></td></tr>";
	echo "<tr><td style='vertical-align: top;'><b>Disable/Enable Account:</b> </td><td>Literally disables account - can no longer logon, send or receive mail. Same as \"Enabled\" checkbox in hMailServer Admin account > general page.<br><br></td></tr>";
	echo "<tr><td style='vertical-align: top;'><b>Lock/Unlock Account:</b> </td><td>Sets account lock switch to 0 or 1. With switch enabled (1), user gets disconnected at every logon attampt, preventing user from logging on or sending mail, but does not interfere with receiving mail.</td></tr>";
	echo "</table>";

	echo "</div>";

?>