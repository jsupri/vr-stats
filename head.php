
	<title>vSphere Replication Stats</title>
	
	<link rel="stylesheet" type="text/css" href="./common/statsMainCSS.css">
	<link rel="stylesheet" type="text/css" href="https://cdn.datatables.net/1.10.20/css/jquery.dataTables.min.css">
	<style type="text/css" class="init">

	</style>
	<script type="text/javascript" language="javascript" src="https://code.jquery.com/jquery-3.3.1.js"></script>
	<script type="text/javascript" language="javascript" src="https://cdn.datatables.net/1.10.20/js/jquery.dataTables.min.js"></script>
	<script type="text/javascript" class="init"> //Start JQUERY
		
		$(document).ready(runjQuery); // END JQUERY
		
		function runjQuery() {
						
			table = $('#table').DataTable( {
				"pageLength": 15
			});
			
			
			$("#nav-<?php echo $pageName; ?>").addClass("active");
			
		}; // END JQUERY
		
	</script>
