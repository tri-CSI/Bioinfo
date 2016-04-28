<?php
/**
 * Full Content Template
 *
   Template Name:  Analysis
 *
 * @file           analysis.php
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
<script language="javascript">
//check inputs - called on submission of form
function checkinput(){
	
	dbvalid = false;
	analysisvalid = true;
	//analysisvalid = false;
	mappingsvalid = false;
	includevalid = false;
	genetypevalid = false;
	

	atitle = document.getElementsByName("atitle");
	if(!atitle[0].value){
		alert("Please input analysis title!");
		return false;
	}
	//check if database complete
	genelistbox = document.getElementsByName("genelistbox");
	genelistfile = document.getElementsByName("genelistfile");
	
	if(!genelistbox[0].value && !genelistfile[0].value){
		alert("Please paste Genelist or input a Genelist file (1)");
		return false;
	}
	if(genelistbox[0].value && genelistfile[0].value){
		alert("Either paste Genelist or input a Genelist file only (1)");
		return false;
	}
	//check if database complete
	db = document.getElementsByName("species");
	var dbLength = db.length;
	for(var i = 0; i < dbLength; i++) {
		if(db[i].checked) {
			genetypevalid = true;
			break;
		}
	}
	
	if(!genetypevalid){
		alert("Please select a Gene type");
		return false;
	}
	
	//check if database complete
	db = document.getElementsByName("db[]");
	var dbLength = db.length;
	for(var i = 0; i < dbLength; i++) {
		if(db[i].checked) {
			dbvalid = true;
			break;
		}
	}

	//check if analysis complete
	analysis = document.getElementsByName("analysis");
	var analysisLength = analysis.length;
	for(var i = 0; i < analysisLength; i++) {
		if(analysis[i].checked) {
			analysisvalid = true;
			break;
		}
	}
	
	//check if mappings complete
	mappings = document.getElementsByName("mappings");
	var mappingsLength = mappings.length;
	for(var i = 0; i < mappingsLength; i++) {
		if(mappings[i].checked) {
			mappingsvalid = true;
			break;
		}
	}
	
	//check if include complete
	include = document.getElementsByName("include");
	var includeLength = include.length;
	for(var i = 0; i < includeLength; i++) {
		if(include[i].checked) {
			includevalid = true;
			break;
		}
	}
	
	//can only complete one section
	if((dbvalid) && (mappingsvalid || includevalid)){
		alert("Please complete only one section (2)");
		return false;
	}
	//if first section done check if all selected
	else if(dbvalid){
		if(analysisvalid){
			return true;
		}
		else{
			alert("Please select analysis collection");
			return false;
		}
	}
	
	//if second section done check if all selected
	if(mappingsvalid){
		if(includevalid){
			return true;
		}
		else{
			alert("Please choose whether to include non-conserved miRNAs");
			return false;
		}
	}
	
	//request for form to be completed
	alert("Please complete at least one section (2)");
	return false;
	
}


function deselectCM() {
	var x = document.getElementsByName("db[]");
	for (var i = 0; i < x.length; i++) {
		x[i].checked = false;
	}
	var x = document.getElementsByName("mappings");
	for (var i = 0; i < x.length; i++) {
		x[i].checked = false;
	}
	var x = document.getElementsByName("include");
	for (var i = 0; i < x.length; i++) {
		x[i].checked = false;
	}
}
</script>
<h1>Input parameters</h1>
        <div id="analysis" class="grid col-940">

<form id="mirVis" name="mirVis" method="post" action="mid.php" onsubmit="return checkinput();" enctype="multipart/form-data">

<table border="0" width="100%">
<tr>
    <td>
	<div style="color:#FFF;background-color:#585858"><strong>Input Analysis title</strong></div><p> Title
        <input name="atitle" type="text" placeholder="my analysis" size="20" maxlength="40" /> </p>
    </td>
  </tr>
  <tr>
    <td>
	<div style="color:#FFF;background-color:#585858"><strong>Input Gene list</strong></div>Paste genes<br />
                <textarea name="genelistbox" id="genelistbox" cols=30></textarea><br />
		or Upload <input name="genelistfile" id="genelistfile" type="file" />
<p> </p><strong>Species:</strong> <input name="species" type="radio" id="species" value="human" /> Human  
<input name="species" type="radio" id="species" value="mouse" /> Mouse
    </td>
  </tr>
  <tr>   
   <td>
<table border="0" width="100%">
      <tr>
        <td width="47%">
		<p><div style="color:#FFF;background-color:#585858"><strong>Choose Specific Database(s)</strong></div></p>
          	<table border="0" cellspacing="20" cellpadding="" width="100%">
            	<tr>
              	  <td><input name="db[]" type="checkbox" id="db1" value="tc"/> <a href="http://www.targetscan.org/">TargetScan (conserved)</a></td>
              	  <td><input name="db[]" type="checkbox" id="db2" value="di" /> <a href="http://diana.cslab.ece.ntua.gr/DianaTools/index.php?r=microtv4/index">Diana</a></td>
                </tr>
                <tr>
                  <td><input name="db[]" type="checkbox" id="db5" value="tnc" /> <a href="http://www.targetscan.org/">TargetScan (non-conserved)</a></td>
                  <td><input name="db[]" type="checkbox" id="db6" value="pic" /> <a href="http://dorina.mdc-berlin.de/rbp_browser/dorina.html">Pictar</a></td>
               </tr>
               <tr>
                  <td><input name="db[]" type="checkbox" id="db4" value="mc" />
                      <a href="http://www.microrna.org/microrna/getDownloads.do">Miranda (conserved)</a></td>
               </tr>
               <tr>
                  <td><input name="db[]" type="checkbox" id="db7" value="mnc"/>
                      <a href="http://www.microrna.org/microrna/getDownloads.do">Miranda (non-conserved)</a></td>
                  <td><input name="db[]" type="checkbox" id="db3" value="mdb" /> <a href="http://mirdb.org/miRDB/">mirDB</a></td>
               </tr>
               <tr>
                  <td><input name="db[]" type="checkbox" id="db8" value="pta"/>
                      <a href="http://genie.weizmann.ac.il/pubs/mir07/mir07_data.htm">PITA</a></td>
                  <td><input name="db[]" type="checkbox" id="db9" value="r22" /> <a href="https://cm.jefferson.edu/data-tools-downloads/rna22-full-sets-of-predictions/">RNA22</a></td>
               </tr>
               </table>
<br/>
<table>
	<tr>
		<td colspan=2>
			<input type="button" value="Uncheck all databases" class="submit" onclick="deselectCM()">
		</td>
	</tr>
</table>

  </table>
</td>
        <td width="9%" align="center">
        <p>.<br />
          .<br />
          .<br /> 
          .<br /> 
          or<br />
          .<br /> 
	.<br />
	.<br />
	.<br />
	</td>
        <td width="44%" valign="top">
        <p><div style="color:#FFF;background-color:#585858"><strong>Get common mappings from</strong></div></p>
          <table border="0" cellspacing="0" cellpadding="0" width="100%">
    		<tr>
      		  <td><input type="radio" name="mappings" id="mappings1" value="1" /> 1 or more databases</td>
      		  <td><input type="radio" name="mappings" id="mappings2" value="2" /> 2 or more databases</td>
    		</tr>
    		<tr>
      		  <td><input type="radio" name="mappings" id="mappings3" value="3" /> 3 or more databases</td>
      		  <td><input type="radio" name="mappings" id="mappings4" value="4" /> 4 or more databases</td>
    		</tr>
    		<tr>
      		  <td><input type="radio" name="mappings" id="mappings5" value="5" /> 5 or more databases</td>
      		  <td><input type="radio" name="mappings" id="mappings6" value="6" /> 6 or more databases</td>
    		</tr>
    		<tr>
      		  <td><input type="radio" name="mappings" id="mappings7" value="7" /> All 7 databases</td>
    		</tr>
  	  </table>
          <br />
          <div style="color:#FFF;background-color:#585858"><strong>Include non-conserved miRNAs?</strong></div>
	  <table border="0" cellspacing="10" cellpadding="0" width="100%">
    		<tr>
      		<td><input type="radio" name="include" id="include1" value="Yes" /> Yes</td>
      		<td><input type="radio" name="include" id="include2" value="No" /> No</td>
    </tr>
  </table></td>
      </tr>
    </table></td>
  </tr>  
  <tr>
    <td>
<div style="color:#FFF;background-color:#585858"><strong>Analysis Thresholds</strong></div>
      <p>
        <input name="hyperthresh" type="text" value="0.0001" size="10" maxlength="10" /> 
        Hypergeometric threshold      </p>
      <p>
        <input name="emthresh" type="text" value="0.001" size="10" maxlength="10" id="emthresh" /> 
        EM threshold<br />
    </p></td>
  </tr>
  <tr>
    <td>
        <input  class="submit" name="submit" type="submit" value="Submit" />
        <input class="submit" name="reset" type="reset" value="Clear All" />

    </td>
  </tr>
  <tr>
    <td>&nbsp;</td>
  </tr>
</table>
</form>        
        </div><!-- end of #content-full -->

<?php get_footer(); ?>
