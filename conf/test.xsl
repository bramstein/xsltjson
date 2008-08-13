<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:exsl="http://exslt.org/common" 
	extension-element-prefixes="exsl"
	xmlns:xsltu="http://xsltunit.org/0/"
	xmlns:json="http://json.org/"
	exclude-result-prefixes="exsl">

	<xsl:import href="xml-to-json.xsl"/>
	<xsl:import href="xsltunit.xsl"/>

	<xsl:output method="xml" version="1.0" encoding="utf-8" indent="yes"/>

	<xsl:template match="tests">
		<xsltu:tests>
			<xsl:for-each select="test">
				<xsltu:test id="{@id}">
					<xsl:call-template name="xsltu:assertEqual">
						<xsl:with-param name="id" select="'output'"/>
						<xsl:with-param name="nodes1">
							<xsl:call-template name="json:build-tree">
								<xsl:with-param name="input">
									<xsl:copy-of select="input/child::node()"/>
								</xsl:with-param>
							</xsl:call-template>
						</xsl:with-param>
						<xsl:with-param name="nodes2">
							<xsl:copy-of select="output/child::node()"/>
						</xsl:with-param>
					</xsl:call-template>
				</xsltu:test>
			</xsl:for-each>
		</xsltu:tests>
	</xsl:template>
</xsl:stylesheet>
