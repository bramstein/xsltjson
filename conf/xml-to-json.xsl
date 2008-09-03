<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="2.0" 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:json="http://json.org/">
	
	<!--
	   Copyright (c) 2006-2008, Bram Stein
	   All rights reserved.
 
	   Redistribution and use in source and binary forms, with or without 
	   modification, are permitted provided that the following conditions 
	   are met:
 
	   1. Redistributions of source code must retain the above copyright
	      notice, this list of conditions and the following disclaimer. 
 	   2. Redistributions in binary form must reproduce the above copyright 
	      notice, this list of conditions and the following disclaimer in the 
	      documentation and/or other materials provided with the distribution. 
	   3. The name of the author may not be used to endorse or promote products 
	      derived from this software without specific prior written permission. 
  
	   THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR IMPLIED 
	   WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
	   MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO 
	   EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
	   INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
	   BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
	   DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY 
	   OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING 
	   NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, 
	   EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 	-->

	<xsl:output indent="no" omit-xml-declaration="yes" method="text" encoding="utf-8"/>
	<xsl:strip-space elements="*"/>

	<!--
	   XSLTJSON v0.7.
	
	   You can use these parameters to control the output by supplying them to 
	   stylesheet. Consult the manual of your XSLT processor for instructions 
	   on how to pass parameters to a stylesheet.
	   
	   * debug 		-  Enable or disable the output of the temporary 
	   			   XML tree used to generate JSON output.
	   * use-rabbitfish	-  Output basic JSON with a '@' to indicate XML
	   			   attributes.
	   * use-badgerfish	-  Use the BadgerFish (http://badgerfish.ning.com/)
	   			   convention to output JSON without XML namespaces.
	   * use-rayfish    - Use the RayFish (http://onperl.org/blog/onperl/page/rayfish)
				   convention to output JSON without XML namespaces.
	   * use-namespaces	-  Output XML namespaces according to the
	   			   BadgerFish convention.
	   * jsonp	        -  Enable JSONP; the JSON output will be prepended with 
				   the value of the jsonp parameter.

	   Credits: 
		Chick Markley (chick@diglib.org) - Octal number & numbers with terminating period
	-->
	<xsl:param name="debug" as="xs:boolean" select="false()"/>
	<xsl:param name="use-rabbitfish" as="xs:boolean" select="false()"/>
	<xsl:param name="use-badgerfish" as="xs:boolean" select="false()"/>
	<xsl:param name="use-namespaces" as="xs:boolean" select="false()"/>
	<xsl:param name="use-rayfish" as="xs:boolean" select="false()"/>
	<xsl:param name="jsonp" as="xs:string" select="''"/>
	
	<!--
		If you import or include the stylesheet in your own stylesheet you
		can use this function to transform any XML node to JSON.
	-->
	<xsl:function name="json:generate" as="xs:string">
		<xsl:param name="input" as="node()"/>
		
		<xsl:variable name="json-tree">
			<json:object>
				<xsl:copy-of select="if (not($use-rayfish)) then json:create-node($input, false()) else json:create-simple-node($input)"/>
			</json:object>
		</xsl:variable>
		
		<xsl:variable name="output">
			<xsl:value-of select="$jsonp"/><xsl:text>(</xsl:text><xsl:apply-templates select="$json-tree" mode="json"/><xsl:text>)</xsl:text>
		</xsl:variable>
		
		<xsl:sequence select="$output"/>
	</xsl:function>

	<!-- 
		Template to match the root node so that the stylesheet can also
		be used on the command line.
	-->
	<xsl:template match="/*">
			<xsl:choose>
				<xsl:when test="$debug">
					<xsl:variable name="json-tree">
						<json:object>
							<xsl:copy-of select="if (not($use-rayfish)) then json:create-node(., false()) else json:create-simple-node(.)"/>
						</json:object>
					</xsl:variable>
							
					<debug>
						<xsl:copy-of select="$json-tree"/>
					</debug>
					<xsl:apply-templates select="$json-tree" mode="json"/>
				</xsl:when>		
				<xsl:otherwise>
					<xsl:value-of select="json:generate(.)"/>
				</xsl:otherwise>
			</xsl:choose>	
	</xsl:template>
	
	<!--
		All methods below are private methods and should not be used
		standalone.
	-->
	<xsl:template name="json:build-tree">
		<xsl:param name="input" as="node()"/>
		<json:object>
			<xsl:copy-of select="if (not($use-rayfish)) then json:create-node($input, false()) else json:create-simple-node($input/child::node())"/>
		</json:object>
	</xsl:template>

	<xsl:function name="json:create-simple-node-member" as="node()">
		<xsl:param name="type" as="xs:string"/>
		<xsl:param name="value"/>
		<json:member>
			<json:name><xsl:value-of select="$type"/></json:name>
			<json:value><xsl:copy-of select="$value"/></json:value>
		</json:member>
	</xsl:function>

	<xsl:function name="json:create-simple-node" as="node()*">
		<xsl:param name="node" as="node()"/>

		<xsl:copy-of select="json:create-simple-node-member('#name', $node/local-name())"/>
		<xsl:copy-of select="json:create-simple-node-member('#text', $node/child::text())"/>

		<xsl:variable name="empty-array">
			<json:array/>
		</xsl:variable>	

		<xsl:variable name="children">
			<json:array>
				<xsl:for-each select="$node/@*">
					<json:array-value>
						<json:value>
							<json:object>
								<xsl:copy-of select="json:create-simple-node-member('#name', concat('@',./local-name()))"/>
								<xsl:copy-of select="json:create-simple-node-member('#text', string(.))"/>
								<xsl:copy-of select="json:create-simple-node-member('#children', $empty-array)"/>
							</json:object>
						</json:value>
					</json:array-value>
				</xsl:for-each>
				<xsl:for-each select="$node/child::element()">
					<json:array-value>
						<json:value>
							<json:object>
								<xsl:copy-of select="json:create-simple-node(.)"/>
							</json:object>
						</json:value>
					</json:array-value>
				</xsl:for-each>
			</json:array>
		</xsl:variable>			
		<xsl:copy-of select="json:create-simple-node-member('#children', $children)"/>
	</xsl:function>

	<xsl:function name="json:create-node" as="node()">
		<xsl:param name="node" as="node()"/>
		<xsl:param name="in-array" as="xs:boolean"/>
		<xsl:choose>
			<xsl:when test="$in-array">
				<json:array-value>
					<json:value>
						<xsl:copy-of select="json:create-children($node)"/>
					</json:value>
				</json:array-value>
			</xsl:when>
			<xsl:otherwise>
				<json:member>
					<xsl:copy-of select="json:create-string($node)"/>
					<json:value>
						<xsl:copy-of select="json:create-children($node)"/>
					</json:value>
				</json:member>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	
	<xsl:function name="json:create-children">
		<xsl:param name="node" as="node()"/>
		<xsl:choose>
			<xsl:when test="exists($node/child::text()) and count($node/child::node()) eq 1">
				<xsl:choose>
					<xsl:when test="(count($node/namespace::*) gt 0 and $use-namespaces) or count($node/@*) gt 0">
						<json:object>
							<xsl:copy-of select="json:create-namespaces($node)"/>
							<xsl:copy-of select="json:create-attributes($node)"/>
							<json:member>
								<json:name>$</json:name>
								<json:value><xsl:value-of select="$node"/></json:value>
							</json:member>
						</json:object>
					</xsl:when>
					<xsl:otherwise>
						<xsl:copy-of select="json:create-text-value($node)"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:when test="exists($node/child::text())">
				<xsl:choose>
					<xsl:when test="(count($node/namespace::*) gt 0 and $use-namespaces) or count($node/@*) gt 0">
						<json:object>
							<xsl:copy-of select="json:create-namespaces($node)"/>
							<xsl:copy-of select="json:create-attributes($node)"/>
							<json:member>
								<json:name>$</json:name>
								<json:value>
									<xsl:copy-of select="json:create-mixed-array($node)"/>
								</json:value>
							</json:member>
						</json:object>
					</xsl:when>
					<xsl:otherwise>
						<xsl:copy-of select="json:create-mixed-array($node)"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:when test="exists($node/child::node()) or ((count($node/namespace::*) gt 0 and $use-namespaces) or count($node/@*) gt 0)">
				<json:object>
					<xsl:copy-of select="json:create-namespaces($node)"/>
					<xsl:copy-of select="json:create-attributes($node)"/>	
					<xsl:for-each-group select="$node/child::node()" group-adjacent="local-name()">
						<xsl:choose>
							<xsl:when test="count(current-group()) eq 1">
								<xsl:copy-of select="json:create-node(current-group()[1], false())"/>
							</xsl:when>
							<xsl:otherwise>
								<json:member>
									<json:name><xsl:value-of select="if($use-namespaces) then current-group()[1]/name() else current-group()[1]/local-name()"/></json:name>
									<json:value>
										<json:array>
											<xsl:for-each select="current-group()">
												<xsl:copy-of select="json:create-node(.,true())"/>
											</xsl:for-each>
										</json:array>
									</json:value>
								</json:member>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:for-each-group>
				</json:object>
			</xsl:when>
		</xsl:choose>
	</xsl:function>
	
	<xsl:function name="json:create-mixed-array" as="node()">
		<xsl:param name="node" as="node()"/>
		<json:array>
			<xsl:for-each select="$node/child::node()">
				<json:array-value>
					<json:value>
						<xsl:choose>
							<xsl:when test="self::text()">		
								<xsl:copy-of select="json:create-text-value(.)"/>
							</xsl:when>
							<xsl:otherwise>	
								<json:object>
									<xsl:copy-of select="json:create-node(.,false())"/>
								</json:object>
							</xsl:otherwise>
						</xsl:choose>
					</json:value>
				</json:array-value>
			</xsl:for-each>
		</json:array>
	</xsl:function>
	
	<xsl:function name="json:create-text-value" as="node()">
		<xsl:param name="node" as="node()"/>
		<xsl:choose>
			<xsl:when test="$use-badgerfish">
				<json:object>
					<json:member>
						<json:name>$</json:name>
						<json:value>
							<xsl:value-of select="$node"/>
						</json:value>
					</json:member>
				</json:object>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$node"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	
	<xsl:function name="json:create-string" as="node()">
		<xsl:param name="node" as="node()"/>
		<xsl:choose>
			<xsl:when test="$use-namespaces">
				<json:name><xsl:value-of select="$node/name()"/></json:name>	
			</xsl:when>
			<xsl:otherwise>
				<json:name><xsl:value-of select="$node/local-name()"/></json:name>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	
	<xsl:function name="json:create-attributes" as="node()*">
		<xsl:param name="node" as="node()"/>
		<xsl:for-each select="$node/@*">
			<json:member>
				<json:name><xsl:if test="$use-badgerfish or $use-rabbitfish">@</xsl:if><xsl:value-of select="if($use-namespaces) then name() else local-name()"/></json:name>
				<json:value><xsl:value-of select="."/></json:value>
			</json:member>
		</xsl:for-each>
	</xsl:function>
	
	<xsl:function name="json:create-namespaces" as="node()*">
		<xsl:param name="node" as="node()"/>
		<xsl:if test="$use-namespaces">
			<xsl:if test="count($node/namespace::*) gt 0">
				<json:member>
					<json:name><xsl:if test="$use-badgerfish or $use-rabbitfish">@</xsl:if>xmlns</json:name>
					<json:value>
						<json:object>
							<xsl:for-each select="$node/namespace::*">
								<json:member>
									<xsl:choose>
										<xsl:when test="prefix-from-QName(node-name($node)) eq ''">
											<json:name>$</json:name>
										</xsl:when>
										<xsl:otherwise>
											<json:name><xsl:value-of select="prefix-from-QName(node-name($node))"/></json:name>
										</xsl:otherwise>
									</xsl:choose>
									<json:value><xsl:value-of select="."/></json:value>
								</json:member>
							</xsl:for-each>
						</json:object>
					</json:value>
				</json:member>
			</xsl:if>
		</xsl:if>
	</xsl:function>
	
	<!-- 
		These are output functions that transform the temporary tree
		to JSON.
	-->
	<xsl:template match="json:object" mode="json">
		<xsl:variable name="members"><xsl:apply-templates mode="json"/></xsl:variable>
		<xsl:text/>{<xsl:text/>
			<xsl:value-of select="string-join($members/member,',')"/> 
		<xsl:text/>}<xsl:text/>
	</xsl:template>

	<xsl:template match="json:member" mode="json">
		<xsl:text/><member><xsl:apply-templates mode="json"/></member><xsl:text/>
	</xsl:template>
	
	<xsl:function name="json:encode-number" as="xs:string">
		<xsl:param name="string" as="xs:string"/>
		<xsl:sequence select="replace(
					replace(
					replace($string,
						'&#xA;',''),
						'&#xD;',''),
						'&#x9;','')"/>
	</xsl:function>
	
	<xsl:function name="json:encode-string" as="xs:string">
		<xsl:param name="string" as="xs:string"/>
		<xsl:sequence select="replace(
					replace(
					replace(
					replace(
					replace(
					replace($string,
						'\\','\\\\'),
						'/', '\\/'),	
						'&quot;', '\\&quot;'),
						'&#xA;','\\n'),
						'&#xD;','\\r'),
						'&#x9;','\\t')"/>
	</xsl:function>
	
	<xsl:template match="json:name" mode="json">
		<xsl:text/>"<xsl:value-of select="json:encode-string(.)"/>":<xsl:text/>
	</xsl:template>

	<xsl:template match="json:value" mode="json">
		<xsl:choose>
			<xsl:when test="node() and not(text())">
				<xsl:apply-templates mode="json"/>
			</xsl:when>
			<xsl:when test="text()">
				<xsl:choose>
					<xsl:when test="string(number(.)) = 'NaN' or ends-with(.,'.') or starts-with(.,'0')">
						<xsl:text/>"<xsl:value-of select="json:encode-string(.)"/>"<xsl:text/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text/><xsl:value-of select="json:encode-number(.)"/><xsl:text/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text/>null<xsl:text/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="json:array-value" mode="json">
		<xsl:text/><value><xsl:apply-templates mode="json"/></value><xsl:text/>
	</xsl:template>

	<xsl:template match="json:array" mode="json">
		<xsl:variable name="values">
			<xsl:apply-templates mode="json"/>
		</xsl:variable>
		<xsl:text/>[<xsl:text/>
			<xsl:value-of select="string-join($values/value,',')"/>
		<xsl:text/>]<xsl:text/>
	</xsl:template>
</xsl:stylesheet>
