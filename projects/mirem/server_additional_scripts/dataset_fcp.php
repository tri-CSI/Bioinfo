<?php

/**
 * Full Content Template
 *
   Template Name:  Dataset with logFC, p-val
 *
 * @file           dataset_fcp.php
 * @package        miREM
 * @author         Tran Minh Tri - CTRAD
 * @version        Release: 1.0
 */
?>
<script type="text/javascript" src="./table_sorter/jquery-1.7.2.min.js"></script> 
<script type="text/javascript" src="./table_sorter/jquery.tablesorter.min.js"></script> 
<script type="text/javascript" >
$(document).ready(function() 
    { 
        $("#myTable").tablesorter(); 
    } 
);
</script>
<base target="_blank">

<link rel="stylesheet" type="text/css" href="./mirem_result_display/tri_theme.css">

<?php get_header(); ?>
<h1 id="atitle">Dataset</h1>
	<div id="analysis" class="grid col-940">

<?php 
	$folder =$_REQUEST["results_id"]; 
	if (strpos($folder,'example') !== false) {
		$folder = "./examples/" . $folder;
	} else {$folder = "./tmp/" . $folder;}
    $gene_list = $folder . "/mirvis_user.txt";
?>

<div style="width:910">
    <!-- Prediction results table-->
    <a href=<?php echo $gene_list; ?>>Show gene list only </a>
	<h2 style="width:100%; float:left;"> Gene list with logFC and p-value</h2>
	<div style="width:100%; float:left;">
			<table id="myTable" class="tablesorter" width="100%">
		<thead> 
     		<tr>
				<th><div><strong>Gene</strong> </div></th> 
				<th><div><strong>log Fold Change</strong></div></th> 
				<th><div><strong>P value </strong></div></th> 
     		</tr>
		</thead> 
		<tbody> 
	<?php
		$file = fopen("$folder/results.txt", "r") or exit("Unable to open file!");
        $file = fopen("$folder/mirvis_user.txt.logFCpval", "r") or exit("Unable to open file!");
		$arr = preg_split("/[\t]/", fgets($file)); //skip first line
	   
		while(!feof($file)) { 
			$arr = preg_split("/[\t]/", fgets($file));
			if (trim($arr[0]) == "") continue;
			
			print "<tr>";
				print "<td style=\"line-height=10px\"><div style=\"font-size:11px;align=\"center\"\">".$arr[0]."</div></td>"; 
				print "<td><div style=\"font-size:11px;align=\"center\"\">".$arr[1]."</div></td>"; 
				print "<td><div style=\"font-size:11px;align=\"center\"\">".$arr[2]."</div></td>"; 
			print "</tr>";
		}	
		fclose($file);
		
	?>
		</tbody> 
			</table>
	</div>

</div>
        </div><!-- end of #content-full -->

<?php get_footer(); ?>
