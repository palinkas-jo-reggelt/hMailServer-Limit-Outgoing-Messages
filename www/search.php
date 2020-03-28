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
	echo "	<form action='search.php' method='GET'>";
	echo "		<input type='text' size='20' name='search' placeholder='Search...' value='".$search."'>";
	echo "		<input type='submit' name='submit' value='Search' >";
	echo "	</form>";
	echo "</div>";

	echo "<div class='section'>";

	$no_of_records_per_page = 20;
	$offset = ($page-1) * $no_of_records_per_page;
	
	$total_pages_sql = $pdo->prepare("
		SELECT Count( * ) AS count 
		FROM hm_accounts_mobile 
		WHERE account LIKE '%".$search."%'
	");
	$total_pages_sql->execute();
	$total_rows = $total_pages_sql->fetchColumn();
	$total_pages = ceil($total_rows / $no_of_records_per_page);

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
		WHERE account LIKE '%".$search."%'
		ORDER BY DATE(lastmessagetime) DESC, messagecount DESC 
		LIMIT ".$offset.", ".$no_of_records_per_page
	);
	$sql->execute();

	if ($search==""){
		$search_res="";
	} else {
		$search_res=" for search term \"<b>".$search."</b>\"";
	}
	
	if ($total_pages < 2){
		$pagination = "";
	} else {
		$pagination = "(Page: ".number_format($page)." of ".number_format($total_pages).")";
	}

	if ($total_rows == 1){$singular = '';} else {$singular= 's';}
	if ($total_rows == 0){
		if ($search == ""){
			echo "Please enter a search term";
		} else {
			echo "No results ".$search_res;
		}	
	} else {
		echo "Results ".$search_res.": ".number_format($total_rows)." Account".$singular." ".$pagination."<br>";
		echo "<table class='section' width='100%'>
			<tr>
				<th colspan='6' style='text-align:center;'>OLDER: NO MESSAGES SENT TODAY</th>
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
				if ($row['accountlock']==0){
					echo "<td>No</td>";
				} elseif ($row['accountlock']==1){
					echo "<td>YES</td>";
				} else {
					echo "<td>ERR</td>";
				}
			echo "</tr>";
		}
		echo "</table>";

		if ($total_pages == 1){echo "";}
		else {
			echo "<ul>";
			if($page <= 1){echo "<li>First </li>";} else {echo "<li><a href=\"?submit=Search&search=".$search."&page=1\">First </a><li>";}
			if($page <= 1){echo "<li>Prev </li>";} else {echo "<li><a href=\"?submit=Search&search=".$search."&page=".($page - 1)."\">Prev </a></li>";}
			if($page >= $total_pages){echo "<li>Next </li>";} else {echo "<li><a href=\"?submit=Search&search=".$search."&page=".($page + 1)."\">Next </a></li>";}
			if($page >= $total_pages){echo "<li>Last</li>";} else {echo "<li><a href=\"?submit=Search&search=".$search."&page=".$total_pages."\">Last</a></li>";}
			echo "</ul>";
		}
	}
?>

<br>
</div> <!-- end of section -->

<?php include("foot.php") ?>