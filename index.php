<?php
$pageName = explode(".", basename($_SERVER['PHP_SELF']))[0];


?>


<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en">

<!------------------
*** Head ****
--------------------->	
<head>
<?php include './common/head.php'; ?>
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
		<p> This is a utility to view vSphere Replication Statistics and logs.</p><br />
		<p> Click the links to the left to explore the relevant data </p>
	</div>
			
	</body>
</html>