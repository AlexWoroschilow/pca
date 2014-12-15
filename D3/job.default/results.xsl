<?xml version="1.0" encoding="utf8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:template match="/">
<table id="results">
  <thead>
    <tr><th>PDB ID</th> <th>Z-score</th> <th>frac DME</th> <th>SW coverage</th> <th>Sequence id</th> <th>Size</th><th>RMSD</th> <th>Q-score</th></tr>
  </thead>
  <tbody>
	<xsl:for-each select="query/results/result">
		<tr id="{@id}" class="hit">
		  <td><xsl:value-of select="pdbid"/></td>
		  <td><xsl:value-of select="z_scr"/></td>
		  <td><xsl:value-of select="f_dme"/></td>
		  <td><xsl:value-of select="sw_cvr"/></td>
		  <td><xsl:value-of select="seq_id"/></td>
		  <td><xsl:value-of select="asize"/></td>
		  <td><xsl:value-of select="rmsd"/></td>
		  <td><xsl:value-of select="q_scr"/></td>
		</tr>
	</xsl:for-each>
  </tbody>
</table>
**/?**<xsl:value-of select="query/params/structure"/>**/?**<xsl:value-of select="query/params/title"/>**/?**<xsl:value-of select="query/params/rmsd_thresh"/>**/?**<xsl:value-of select="query/params/min_f_dme"/>**/?**<xsl:value-of select="query/params/max_n"/>**/?**<xsl:value-of select="query/params/jobfolder"/>**/?**<xsl:value-of select="query/params/add_to_calc"/>**/?**

</xsl:template>
</xsl:stylesheet>


