<?xml version="1.0" encoding="utf8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:template match="/">
<table>
<xsl:for-each select="wait/params/*">
  <tr>
    <td><xsl:value-of select="name()"/></td>
    <td><xsl:value-of select="."/></td>
  </tr>
</xsl:for-each>
</table>**/?**
<xsl:for-each select="wait/warnings/failure">
  <div class="failure"><xsl:value-of select="."/></div>
</xsl:for-each>
<xsl:for-each select="wait/warnings/success">
  <div class="success"><xsl:value-of select="."/></div>
</xsl:for-each>
<xsl:for-each select="wait/warnings/warn">
  <div class="warn"><xsl:value-of select="."/></div>
</xsl:for-each>
**/?**<xsl:value-of select="wait/time/day"/>.<xsl:value-of select="wait/time/month"/>.<xsl:value-of select="wait/time/year"/> - <xsl:value-of select="wait/time/hour"/>:<xsl:value-of select="wait/time/min"/>:<xsl:value-of select="wait/time/sec"/>**/?**


</xsl:template>
</xsl:stylesheet>



<!--

var converted = data.split("**/?**");

$("#query").html(converted[0]);
$("#warning").html(converted[1]);
$("#time").html(converted[2]);
$("#started_at").html(converted[3]);



<wait>
 <params>
  <Query_structure>1kntA</Query_structure>
  <Submitted_Title>result id=pdbid</Submitted_Title>
  <E-mail>Anonymous</E-mail>
  <rmsd_Threshold>3</rmsd_Threshold>
  <minimal_FracDME>0.75</minimal_FracDME>
  <number_of_results>100</number_of_results>
  <add_to_calculated_results>no</add_to_calculated_results>
 </params>

 <warnings>
  <success>Your query PDB ID could be found in the official database.</success>
  <warn>You have not provided an E-mail address. Therefore, you will not be notified by E-mail as soon as the results are ready.</warn>
 </warnings>

 <time>
  <year>2014</year>
  <month>05</month>
  <day>09</day>
  <hour>12</hour>
  <min>39</min>
  <sec>16</sec>
 </time>
</wait>
-->





