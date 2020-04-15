

<?php
$pageTitle = "VR Configured";

$pageFile = explode(".", basename($_SERVER['PHP_SELF']))[0];

#$dbtable = preg_replace("/[^a-zA-Z]/", "", $pageTitle);
$pageName = $pageFile;

#Import username, password, 
include './common/dbCreds.php';

// Below is optional, remove if you have already connected to your database.
$mysqli = mysqli_connect("localhost", $dbuser, $dbpass, $dbname);

?>


<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en">

<!------------------
*** Head ****
--------------------->	
<head>
<?php include './common/head.php'; ?>

		<script>
		var table;
		
		function getTable(str) 
		{
			
			table.destroy();
									
			
			var xhttp;    
			if (str == "") 
			{
				document.getElementById("getTable").innerHTML = "";
				return;
			}
			xhttp = new XMLHttpRequest();
			xhttp.onreadystatechange = function() 
			{
				if (this.readyState == 4 && this.status == 200) {
					document.getElementById("getTable").innerHTML = this.responseText;
				}
			};
			xhttp.open("POST", "getTable.php?q="+str, true);
			xhttp.send();
			
			
		setTimeout(
			function()
			{table = $('#table').DataTable( {
				"pageLength": 15
			});}, 200);
		}	
		</script>

</head>
<!------------------
*** Body ****
--------------------->		
	
	<body>
		<div id="pageHeader">
			<h1>vSphere Replication Statistic Viewer</h1>
		</div>
			
<!------------------
	*** NavBar ****
--------------------->			

<?php include './common/navBar.php'; ?>


<!------------------
*** MAIN Body ****
--------------------->				
	<div id="mainBody">
		<form action="" method="">
		<select id="selectTable" onchange="getTable(this.value)">
			<option selected disabled>Choose a Table</option>	
	<?php	
		$dbquery = "show tables";
		if ($result = $mysqli->query($dbquery)) {
			while ($row = $result->fetch_row()): 
				echo "<option value=" .$row[0]. ">" . $row[0] . "</option>\n";
			endwhile;
		}		
	?>
		</select>
		</form><br /><br /><br />
		
		<div id="getTable">
		<table id="table" class="display">
			<thead>
			<tr>
				<th></th>
			</tr>
			</thead>
			
			<tbody>
			<tr>
				<td></td>
			</tr>
			</tbody>
		</table>
		</div>
	</div>
			
	</body>
</html>
