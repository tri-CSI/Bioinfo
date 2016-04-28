<?php

/**
 * Full Content Template
 *
   Template Name:  Results
 *
 * @file           results.php
 * @package        miREM
 * @author         Tran Minh Tri - CTRAD
 * @version        Release: 1.0
 */
?>
<link rel="stylesheet" type="text/css" href="./mirem_result_display/tri_theme.css">
<script src="http://eligrey.com/demos/FileSaver.js/Blob.js"></script>
<script type="text/javascript" src="./mirem_result_display/FileSaver.min.js"></script>
<script type="text/javascript" src="./mirem_result_display/d3.min.js"></script> 
<script type="text/javascript" src="./mirem_result_display/d3-tip.js"></script> 
<script type="text/javascript" src="./mirem_result_display/scatterplot.js"></script> 
<script type="text/javascript" src="./mirem_result_display/phyloplot.js"></script> 
<script type="text/javascript" src="./mirem_result_display/heatmap.js"></script> 
<script type="text/javascript" src="./mirem_result_display/jsphylosvg-1.55/raphael-min.js"></script> 
<script type="text/javascript" src="./mirem_result_display/jsphylosvg-1.55/jsphylosvg.js"></script> 

<script type="text/javascript" src="./table_sorter/jquery-1.7.2.min.js"></script> 
<script type="text/javascript" src="./table_sorter/jquery.tablesorter.min.js"></script> 
<script type="text/javascript" >
$.tablesorter.addParser({ 
	// set a unique id
	id: 'scinot', 
	is: function(s) { 
	    return /[+\-]?(?:0|[1-9]\d*)(?:\.\d*)?(?:[eE][+\-]?\d+)?/.test(s); 
	}, 
	format: function(s) { 
	    return $.tablesorter.formatFloat(s);
	}, 
	type: 'numeric' 
});
 
    // add parser through the tablesorter addParser method 
    $.tablesorter.addParser({ 
        // set a unique id 
        id: 'ratio', 
        is: function(s) { 
            // return false so this parser is not auto detected 
            return false; 
        }, 
        format: function(s) { 
            // format your data for normalization 
            return s.toLowerCase().replace(/\/.*/,""); 
        }, 
        // set type, either numeric or text 
        type: 'numeric' 
    }); 

$(document).ready(function() 
    { 
        $("#myTable").tablesorter({ 
            headers: { 
                4: { 
                    sorter:'ratio' 
                } 
            } 
        }); 
    } 
);
</script>

<?php get_header(); ?>
<h1 id="atitle">Analysis result</h1>
	<div id="analysis" class="grid col-940">

<?php 
	$folder =$_REQUEST["results_id"]; 

	if (strpos($folder,'example') !== false) {
		$folder = "./examples/" . $folder;
	} else {$folder = "./tmp/" . $folder;}

    if (file_exists("$folder/not_ready.txt")) { 
	    print "<div align=\"center\">Do refresh this page again in the next 1-5 minutes for the results<br>[Browser auto-refreshes in 10 seconds]</div>"; 
    	print "<META HTTP-EQUIV=\"REFRESH\" CONTENT=\"10\">";
    }   

    else {
        print "<p>"; 
        $file = fopen("$folder/options.txt", "r") or exit("Unable to open file!");
        
        $atitle = fgets($file);
        if(strpos($atitle, "Date of analysis") !== false) { echo $atitle. "<br/>"; } 
        while(!feof($file)) { echo fgets($file). "<br />"; }
        fclose($file);
        $thislink = $_SERVER['SERVER_NAME'] . $_SERVER['REQUEST_URI'];
        $linkencode = urlencode($thislink);
        
        print 'Share your analysis result: <a href="mailto:yourfriend@example.com?Subject=miREM%20Analysis%20results%20for%20'. $atitle . '&body=Here%20is%20a%20miREM%20analysis%20I%20would%20like%20to%20share%20with%20you:%0Ahttp://' . $linkencode . '.%0AThis%20link%20will%20expire%20in%207%20days.">email</a> (will expire after 7 days)</br>';
        print "Download analysis <a href=\"$folder/mirem_analysis.tar.gz\">here</a>";
        print "</p>";
?> 
    <ol>

        <li><a href="#scatPlot"> Scatter-plot of EM probabilities vs hyper-geometric p-values </a></li>

        <li><a href="#phyloPlot"> Predicted miRNA mature sequences clustering </a></li>

        <li><a href="#myTable"> Result table </a></li>

        <li><a href="#heatmap"> Heatmap of predicted miRNA targets </a></li>

    </ol>

<div style="width:910">
	<!-- Scatter plot -->
	</br>
	<h2 id="scatPlot" > Graph plot </h2>
	<p >Click on data point to show gene list, double-click on pop-up to cancel</p>
	<div id="scatterplot">
		<div id="svgdataurl" hidden> </div>
		<button id="savegraph", type="button">Save plot as PNG</button>
		<div id="scatterplotarea" > </div>
	</div>

    <h2 id="phyloPlot" > Predicted miRNA mature sequences clustering</h2>

        <p >miRNAs are highlighted according their  <b>EM</b> scores.<br/>

    Barchart shows <b>-log( adjusted HG p-value )</b><br/>

    Hover on miRNA IDs to exact prediction information.</p>

    <div style="position:absolute; width:100px; float:left;" id="scale"><img src="scale.png"/></div>

    <input style="float:right;" type="button" value="Save phylo tree as SVG" id="savephylo">

    <div style="float:right;" id="phyloCanvas"></div>
    	
    <!-- Prediction results table-->
	<h2 style="width:100%; float:left;"> Result table </h2>
	<div style="width:65%; float:left;">
			<table id="myTable" class="tablesorter" width="100%">
		<thead> 
     		<tr>
				<th><div><strong>miRNA<br></strong> </div></th> 
				<th><div><strong>Hypergeometric<br>p-value</strong></div></th> 
				<th><div><strong>Hypergeometric<br>p-value (adj)</strong></div></th> 
				<th><div><strong>EM<br>probability</strong></div></th> 
				<th><div><strong>Ratio<br> </strong></div></th> 
     		</tr>
		</thead> 
		<tbody> 
	<?php
		$file = fopen("$folder/results.txt", "r") or exit("Unable to open file!");
		$arr = preg_split("/[\t]/", fgets($file)); //skip first line
		$hg_value = array(); $em_value = array(); $mirna = array();
	   
		while(!feof($file)) { 
			$arr = preg_split("/[\t]/", fgets($file));
			if (trim($arr[0]) == "") continue;
			array_push($mirna, $arr[0]);
			array_push($hg_value, $arr[2]);
			array_push($em_value, $arr[3]);
			
			print "<tr>";
				print "<td style=\"line-height=10px\"><div style=\"font-size:11px;align=\"center\"\">".$arr[0]."</div></td>"; 
				print "<td><div style=\"font-size:11px;align=\"center\"\">".$arr[1]."</div></td>"; 
				print "<td><div style=\"font-size:11px;align=\"center\"\">".$arr[2]."</div></td>"; 
				print "<td><div style=\"font-size:11px;align=\"center\"\">".$arr[3]."</div></td>"; 
				print "<td><div style=\"font-size:11px;align=\"center\"\">".$arr[4]."</div></td>"; 
			print "</tr>";
		}	
		fclose($file);
		
		$file = fopen("$folder/results_full.txt", "r") or exit("Unable to open file!");
		$arr = preg_split("/[\t]/", fgets($file)); //skip first line
		$glist = array();   
	    //result_full
		while(!feof($file)) { 
			$arr = preg_split("/[\t]/", fgets($file));
			if (trim($arr[0]) == "") continue;
			array_push($glist, $arr[5]);
		}	
		fclose($file);
	?>
		</tbody> 
			</table>
	</div>
	
	<!-- HEATMAP -->
	<div id="heatmap" style="width:35%; float:left;">
	<p style="width:80%; float:right;"> Top 50 miRNAs with EM score. <br/> Click on miRNA name to show gene list, double-click on pop-up to cancel</p>
	</div>
	<script>		
		var atitle= <?php echo json_encode($atitle ); ?>;
		if (atitle.indexOf("Date of analysis") == -1) {
			document.getElementById("atitle").innerHTML = "Analysis result for " + atitle;
		}
		var hgValue= <?php echo json_encode($hg_value ); ?>;
		var emValue= <?php echo json_encode($em_value ); ?>;
		var miRna= <?php echo json_encode($mirna ); ?>;
		var gList= <?php echo json_encode($glist ); ?>;
		var logHg = hgValue.map(function(d) {return - Math.log10(d);});
		var plotData = [];
		for (var i=0; i < logHg.length && i < emValue.length; i++) { 
			plotData.push([logHg[i], Number(emValue[i]) || 0, miRna[i], gList[i]]) 
		}
		
        var svgSource = '';
		PlotScatter("#scatterplotarea", plotData);
		PlotHeatmap("<?php echo $folder; ?>/matrix_cluster.txt");

        $(document).ready(function(){
            var uri = "<?php echo $folder; ?>/mirna_aligned.phy_phyml_tree.xml" ; 
            $.get(uri, function(data) {
                var dataObject = {
                    xml: data,
                    fileSource: true
                };      
                phylocanvas = new Smits.PhyloCanvas(
                    dataObject,
                    'phyloCanvas', 
                    850, 900,
                    'circular'
                );
                svgSource = phylocanvas.getSvgSource();
            });
        });
        PlotPhylo();
        
	</script>
<?php } ?>

</div>
        </div><!-- end of #content-full -->

<?php get_footer(); ?>
