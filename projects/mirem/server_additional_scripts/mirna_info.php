<?php

/**
 * Full Content Template
 *
   Template Name:  miRNAtarget
 *
 * @file           mirna_info.php
 * @package        miREM
 * @author         Tran Minh Tri - CTRAD
 * @version        Release: 1.0
 */
?>
<script type="text/javascript" src="./table_sorter/jquery-1.7.2.min.js"></script> 
<script type="text/javascript" src="./table_sorter/jquery.tablesorter.min.js"></script> 
<link rel="stylesheet" type="text/css" href="./mirem_result_display/tri_theme.css">

<?php get_header(); ?>
<?php
    parse_str(parse_url($_SERVER['HTTP_REFERER'], PHP_URL_QUERY), $callerargs);
    if (array_key_exists('results_id', $callerargs))
    {
        $filter = True;
        $case = $callerargs['results_id'];
        if (strpos($case,'example') !== false) {
            $folder = "./examples/" . $case;
        } else {$folder = "./tmp/" . $case;}
        $file = $folder . "/mirvis_user.txt.convert.dedup.txt";
        $opfile = fopen("$folder/options.txt", "r") or exit("Unable to open file!");
        $atitle = fgets($opfile);
        $gene_list = file($file, FILE_IGNORE_NEW_LINES );
    }
    else
    { 
        $filter = False;
    }

	$database = '/var/www/mirem2/mirvis_progs/mirem.db';

    $mirna_name = $_REQUEST["mirna_name"]; 
    
    class MyDB extends SQLite3 
    {
        function __construct( $database )
        {
            $this->open( $database );
        }
    }
    
    $db = new MyDB( $database );
    
    if(!$db){
        echo $db->lastErrorMsg();
    } else {
//        echo "Opened database successfully\n";
    } 
    
    $dbnames = array( "TargetScan (Conserved)" => array(), "TargetScan (Non-conserved)" => array(), "Diana" => array(), "miRDB" => array(), "Miranda (Conserved)" => array(), "Miranda (Non-conserved)" => array(), "pictar" => array(), "PITA" => array(), "RNA22" => array() );

    foreach ( $dbnames as $name => &$data ) { 
        $sql = <<<EOF
            SELECT genename FROM Genes g
            JOIN GeneMirnaRec gmr ON g.id = gmr.gene_id
            JOIN Mirna m ON m.id = gmr.mirna_id
            JOIN Databases d ON d.id = gmr.database_id
            WHERE m.mirna = '{$mirna_name}'
            AND d.dbname = '{$name}'
            ORDER BY genename
EOF;

        $ret = $db->query($sql);
        $count = 0;
        while ($row = $ret->fetchArray(SQLITE3_ASSOC) ){
            $gene = $row['genename']; 
            if (!$filter or in_array($gene, $gene_list))
                array_push($data, $gene );
        }
    }
    $db->close();
?>

<h1>Gene count for <?php 
    echo $mirna_name;
?></h1>
<?php
    if ($filter) echo "<h2> Analysis title: ", $atitle, "</h2>";
?>
<div id="analysis" class="grid col-940">
    <div style="width:910">
        <!-- Prediction results table-->
        <div style="width:100%; float:left;">
            <table id="myTable" class="tablesorter" width="100%">
            <thead> 
                <tr>
                    <th><div><strong>TargetScan<br>(Conserved)</strong> </div></th> 
                    <th><div><strong>TargetScan<br>(Non-conserved)</strong> </div></th> 
                    <th><div><strong>Diana</strong></div></th> 
                    <th><div><strong>MirDB</strong></div></th> 
                    <th><div><strong>Miranda<br>(Conserved)</strong> </div></th> 
                    <th><div><strong>Miranda<br>(Non-conserved)</strong> </div></th> 
                    <th><div><strong>Pictar</strong></div></th> 
                    <th><div><strong>PITA</strong></div></th> 
                    <th><div><strong>RNA22</strong></div></th> 
                </tr>
            </thead> 
            <tbody> 
                <tr>
<?php
    $cell = '';
    foreach( $dbnames as $name => &$data ) {
        $cell .= "<td align='center'>";
        $cell .= count( $data );
        $cell .= "</td>";
    }
    print $cell;
?>
                </tr>
                <tr>
<?php
    $cell = '';
    foreach( $dbnames as $name => &$data ) {
        $cell .= "<td valign='top'>";
        foreach( $data as $gene ) { 
            $cell .= "$gene <br/>";
        }
        $cell .= "</td>";
    }
    print $cell;
?>
                </tr>
            </tbody> 
            </table>
        </div>
        
    </div>
</div><!-- end of #content-full -->

<?php get_footer(); ?>
