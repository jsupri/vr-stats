<?php
$dbtable = $_REQUEST["q"];

#
include './common/dbCreds.php';

// Below is optional, remove if you have already connected to your database.
$mysqli = mysqli_connect("localhost", $dbuser, $dbpass, $dbname);


echo "<table id='table' class='display'>\n";
echo "<thead>\n";
echo "\t\t<tr>\n";
			//Loop through HEADERS from DB
			$dbquery = "SELECT `COLUMN_NAME` FROM `INFORMATION_SCHEMA`.`COLUMNS` WHERE `TABLE_SCHEMA`='" . $dbname . "' AND `TABLE_NAME`='" . $dbtable . "'";
			if ($result = $mysqli->query($dbquery)) {
				while ($row = $result->fetch_row()): 
					echo "\t\t\t\t<th>" . $row[0] . "</th>\n";
				endwhile;
			}
echo "\t\t</tr>";
echo "\t</thead>";
			
echo "\t<tbody>";
 //Loop through ROWS from DB
			$dbquery = 'SELECT * FROM ' . $dbtable;
			if ($result = $mysqli->query($dbquery)) {
				while ($row = $result->fetch_row()): 
					echo "\t\t\t<tr>\n";
			
					foreach ($row as $value){
						echo "\t\t\t\t<td>". $value . "</td>\n";
					}
					
					echo "\t\t\t</tr>\n";
						 
				endwhile; 
			}

echo "\t</tbody>";
echo "</table>";
?>