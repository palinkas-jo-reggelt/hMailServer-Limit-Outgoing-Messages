<?php include("head.php") ?>

<?php
	include_once("config.php");
	include_once("functions.php");

	if (isset($_GET['page'])) {
		$page = $_GET['page'];
		$display_pagination = 1;
	} else {
		$page = 1;
		$total_pages = 1;
		$display_pagination = 0;
	}
	if (isset($_GET['submit'])) {$button = $_GET['submit'];} else {$button = "";}
	if (isset($_GET['search'])) {$search = $_GET['search'];} else {$search = "";}

	echo "<br><br>";
	echo "<div class='section'>";

	$total_pages_sql = $pdo->prepare("
		SELECT Count( * ) AS count 
		FROM hm_accounts_mobile 
		WHERE messagecount > 0 AND DATE(lastmessagetime) = DATE(NOW())
	");
	$total_pages_sql->execute();
	$total_rows = $total_pages_sql->fetchColumn();

	$sql = $pdo->prepare("
		SELECT 
			account, 
			mobilenumber, 
			lastlocktime, 
			lastlogontime, 
			lastmessagetime, 
			messagecount, 
			accountdisabled,
			accountlock 
		FROM hm_accounts_mobile 
		WHERE messagecount > 0 AND DATE(lastmessagetime) = DATE(NOW())
		ORDER BY DATE(lastmessagetime) DESC, messagecount DESC 
	");
	$sql->execute();
	
	echo "<table class='section' width='100%'>
		<tr>
			<th colspan='6' style='text-align:center;'>TODAY'S MESSAGES: ".$total_rows."</th>
		</tr>
		<tr>
			<th>Account</th>
			<th>Last Logon</th>
			<th>Last Message</th>
			<th># Msgs</th>
			<th>Locked</th>
		</tr>";
	while($row = $sql->fetch(PDO::FETCH_ASSOC)){
		echo "<tr style='text-align:center;'>";
			echo "<td style='text-align:left;'><a href='account.php?account=".$row['account']."'>".$row['account']."</a></td>";
			echo "<td>".date("y/n/j G:i:s", strtotime($row['lastlogontime']))."</td>";
			echo "<td>".date("y/n/j G:i:s", strtotime($row['lastmessagetime']))."</td>";
			echo "<td>".$row['messagecount']."</td>";
			if (($row['accountlock']==0) && ($row['accountdisabled']==0)){
				echo "<td>No</td>";
			} elseif (($row['accountlock']==1) || ($row['accountdisabled']==1)){
				echo "<td>YES</td>";
			} else {
				echo "<td>ERR</td>";
			}
		echo "</tr>";
	}
	echo "</table>";
	echo "<br><br><br>";

	$total_pages_yesql = $pdo->prepare("
		SELECT Count( * ) AS count 
		FROM hm_accounts_mobile 
		WHERE accountlock = 1
	");
	$total_pages_yesql->execute();
	$total_yes_rows = $total_pages_yesql->fetchColumn();

	$yesql = $pdo->prepare("
		SELECT 
			account, 
			mobilenumber, 
			lastlocktime, 
			lastlogontime, 
			lastmessagetime, 
			messagecount, 
			accountdisabled,
			accountlock 
		FROM hm_accounts_mobile 
		WHERE accountlock = 1
		ORDER BY DATE(lastlocktime) DESC
	");
	$yesql->execute();
	
	echo "<table class='section' width='100%'>
		<tr>
			<th colspan='6' style='text-align:center;'>LOCKED ACCOUNTS: ".$total_yes_rows."</th>
		</tr>
		<tr>
			<th>Account</th>
			<th>Last Logon</th>
			<th>Last Message</th>
			<th># Msgs</th>
			<th>Locked</th>
		</tr>";
	while($row = $yesql->fetch(PDO::FETCH_ASSOC)){
		echo "<tr style='text-align:center;'>";
			echo "<td style='text-align:left;'><a href='account.php?account=".$row['account']."'>".$row['account']."</a></td>";
			echo "<td>".date("y/n/j G:i:s", strtotime($row['lastlogontime']))."</td>";
			echo "<td>".date("y/n/j G:i:s", strtotime($row['lastmessagetime']))."</td>";
			echo "<td>".$row['messagecount']."</td>";
			if (($row['accountlock']==0) && ($row['accountdisabled']==0)){
				echo "<td>No</td>";
			} elseif (($row['accountlock']==1) || ($row['accountdisabled']==1)){
				echo "<td>YES</td>";
			} else {
				echo "<td>ERR</td>";
			}
		echo "</tr>";
	}
	echo "</table>";
	echo "<br><br><br>";

	$total_pages_disql = $pdo->prepare("
		SELECT Count( * ) AS count 
		FROM hm_accounts_mobile 
		WHERE accountdisabled = 1
	");
	$total_pages_disql->execute();
	$total_dis_rows = $total_pages_disql->fetchColumn();

	$disql = $pdo->prepare("
		SELECT 
			account, 
			mobilenumber, 
			lastlocktime, 
			lastlogontime, 
			lastmessagetime, 
			messagecount, 
			accountdisabled,
			accountlock 
		FROM hm_accounts_mobile 
		WHERE accountdisabled = 1
		ORDER BY DATE(lastmessagetime) DESC
	");
	$disql->execute();
	
	echo "<table class='section' width='100%'>
		<tr>
			<th colspan='6' style='text-align:center;'>DISABLED ACCOUNTS: ".$total_dis_rows."</th>
		</tr>
		<tr>
			<th>Account</th>
			<th>Last Logon</th>
			<th>Last Message</th>
			<th># Msgs</th>
			<th>Locked</th>
		</tr>";
	while($row = $disql->fetch(PDO::FETCH_ASSOC)){
		echo "<tr style='text-align:center;'>";
			echo "<td style='text-align:left;'><a href='account.php?account=".$row['account']."'>".$row['account']."</a></td>";
			echo "<td>".date("y/n/j G:i:s", strtotime($row['lastlogontime']))."</td>";
			echo "<td>".date("y/n/j G:i:s", strtotime($row['lastmessagetime']))."</td>";
			echo "<td>".$row['messagecount']."</td>";
			if (($row['accountlock']==0) && ($row['accountdisabled']==0)){
				echo "<td>No</td>";
			} elseif (($row['accountlock']==1) || ($row['accountdisabled']==1)){
				echo "<td>YES</td>";
			} else {
				echo "<td>ERR</td>";
			}
		echo "</tr>";
	}
	echo "</table>";
?>

<br>
</div> <!-- end of section -->

<?php include("foot.php") ?>