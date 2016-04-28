<?php
/**
 * Full Content Template
 *
   Template Name:  Mid
 *
 * @file           mid.php
 * @package        Responsive 
 * @author         Emil Uzelac 
 * @copyright      2003 - 2011 ThemeID
 * @license        license.txt
 * @version        Release: 1.0
 * @filesource     wp-content/themes/responsive/full-width-page.php
 * @link           http://codex.wordpress.org/Theme_Development#Pages_.28page.php.29
 * @since          available since Release 1.0
 */
?>
<?php get_header(); ?>
        <div id="analysis" class="grid col-940">
<?
error_reporting(E_ALL);
ini_set("display_errors",1);

//user given
$list_txt = $_REQUEST["genelistbox"];
$list_file = basename($_FILES["genelistfile"]["name"]);

if(($list_txt == "") and ($list_file <> "")) {$list_txt = 0;}
else if ($list_txt <> "" and $list_file == "") {
	$list_file = "mirvis_user.txt";
	system("touch tmp/$list_file");
	system("chmod 777 tmp/$list_file");
	system("echo \"$list_txt\" > tmp/$list_file");
}
$genus = $_REQUEST["species"];

$db_to_use="";$union_intx="";$mappings="";$include="";

//analysis type 1
if(isset($_REQUEST["db"])) { $db_to_use = $_REQUEST["db"]; }
if(isset($_REQUEST["analysis"])) {$union_intx = $_REQUEST["analysis"]; }

//analysis type 2
if(isset($_REQUEST["mappings"])){ $mappings = $_REQUEST["mappings"]; }
if(isset($_REQUEST["include"])){ $include = $_REQUEST["include"] ;}

//create user directory
$user_base_name = "mirvis_".time();
$user_folder = "/var/www/mirvis/tmp/$user_base_name";
$user_file = "$user_folder"."/"."$list_file";

system("mkdir $user_folder");
system("chmod -R 777 $user_folder");

if($list_txt <> "") {print "mv tmp/$list_file $user_file <br>"; system ("mv tmp/$list_file $user_file"); }
else if($list_txt == "") {print "not mv <br>"; move_uploaded_file($_FILES["genelistfile"]["tmp_name"], $user_file); }

chdir($user_folder);
//echo getcwd() . "\n";
print "
list_txt = $list_txt <br>
list_file = $list_file <br>
genus = $genus <br>
db = $db_to_use <br>
union_intx = $union_intx <br>
map = $mappings <br>
incl = $include <br>
base = $user_base_name <br>
use_fold = $user_folder <br>
file = $user_file <br>
";
for($i=0; $i<count($db_to_use); $i++) {
	print $db_to_use[$i]."<br>";
}
//run!
//system("echo 'Your analysis is still running. Please refresh the browser after ~15 minutes to see if your analysis is done.' > /var/www/mirsnv/tmp/$user_base_name/results.html");


?>

        </div><!-- end of #content-full -->
<?php get_footer(); ?>
