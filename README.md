## XSLTJSON: Transforming XML to JSON using XSLT

XSLTJSON is an XSLT 2.0 stylesheet to transform arbitrary XML to [JavaScript Object Notation](http://json.org/) (JSON). JSON is a lightweight data-interchange format based on a subset of the [JavaScript language](http://en.wikipedia.org/wiki/JavaScript), and often offered as an alternative to XML in—for example—web services. To make life easier XSLTJSON allows you to transform XML to JSON automatically.

XSLTJSON supports several different JSON output formats, from a compact output format to support for the [BadgerFish convention](http://badgerfish.ning.com/), which allows round-trips between XML and JSON. To make things even better, it is completely free and open-source. If you do not have an XSLT 2.0 processor, you can use XSLTJSON Lite, which is an XSLT 1.0 stylesheet to transforms XML to the [JSONML format](http://jsonml.org/).

## Usage

There are three options in using XSLTJSON. You can call the stylesheet from the command line, programmatically, or import it in your own stylesheets.

The stylesheet example below would transform any node matching `my-node` to JSON. If you import XSLTJSON in your stylesheet, you have to add the JSON namespace `xmlns:json="http://json.org/"` to your stylesheet because all functions and templates are in that namespace. The `json:generate()` function takes a XML node as input, generates a JSON representation of that node and returns it as an `xs:string`. This is the only function you should call from your stylesheet.

    <?xml version="1.0" encoding="utf-8"?>
    <xsl:stylesheet version="2.0" 
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
        xmlns:xs="http://www.w3.org/2001/XMLSchema"
        xmlns:json="http://json.org/">
        <xsl:import href="xml-to-json.xsl"/>
        <xsl:template match="my-node">
            <xsl:value-of select="json:generate(.)"/>
        </xsl:template>
    </xsl:stylesheet>

If your stylesheet's sole purpose is to transform XML to JSON, it would be easier to use the `xml-to-json.xsl` stylesheet directly from the command line. The following line shows how to do that using [Java](http://java.sun.com/) and [Saxon](http://www.saxonica.com/).

    java net.sf.saxon.Transform source.xml xml-to-json.xsl

You can also call the stylesheet programmatically, but this depends heavily on your programming environment, so please consult the documentation of your programming language or XSLT processor.

### Parameters

There are five Boolean parameters to control the stylesheet, and all are turned off by default (set to `false()`.) You can control them from the command line, from your program or from another stylesheet. Four of the parameters are used to control the output format and are discussed in more detail in the section on output formats.

* `use-badgerfish` — Use the [BadgerFish](http://badgerfish.ning.com/) convention to output JSON *without* XML namespaces.
* `use-rabbitfish` — Output basic JSON with an `@` to mark XML attributes.
* `use-rayfish` — Use the [Rayfish](http://onperl.org/blog/onperl/page/rayfish) convention to output JSON *without* XML namespaces.
* `use-namespaces` — Output XML namespaces according to the BadgerFish convention.
* `debug` — Enable or disable the output of the temporary XML tree used to generate JSON. Note that turning this on invalidates the JSON output.
* `jsonp` — Enable [JSONP](http://bob.pythonmac.org/archives/2005/12/05/remote-json-jsonp/); prepend the JSON output with the given string. Defaults to an empty string.
* `skip-root` — Enable or disable skipping the root element and returning only the child elements of the root. Disabled by default.

For example; to transform `source.xml` to BadgerFish JSON with Saxon, you would invoke the following on the command line:

    java net.sf.saxon.Transform source.xml xml-to-json.xsl use-badgerfish=true()

For other options consult the [Saxon manual](http://www.saxonica.com/documentation/index/intro.html), or your XSLT processor's documentation.

If you import the stylesheet in your own stylesheet you can override the default parameters by redefining them. So if you want to output JSON using the BadgerFish convention, you should add the following parameter definition to your stylesheet.

        <xsl:param name="use-badgerfish" as="xs:boolean" select="true()"/>

You can force the creation of an array by adding the `force-array` parameter to your XML. So instead of creating two nested objects, the following example will create an object containing an array.

    <list json:force-array="true" xmlns:json="http://json.org/">
      <item>one</item>
    </list>
    
    {list: {item: ['one']}}

The `force-array` attribute will not be copied to the output JSON .

### Output formats

There are four output formats in XSLTJSON, which one to use depends on your target application. If you want the most compact JSON, use the basic output. If you want to transform XML to JSON and JSON back to XML, use the [BadgerFish](http://badgerfish.ning.com/) output. If you want something in between, you could use the RabbitFish output; which is similar to the basic version, but does distinguish between elements and attributes. If you're dealing with a lot of data centric XML, you could use the highly structured Rayfish output. All four output formats ignore XML namespaces unless the `use-namespaces` parameter is set to `true()`, in which case namespaces are created according to the BadgerFish convention.

Each format has a list of rules by which XML is transformed to JSON. The examples for these rules are all but one taken from the [BadgerFish convention website](http://badgerfish.ning.com/) to make comparing them easier.

#### Basic output (default)

The purpose of the basic output is to generate the most compact JSON possible. This is useful if you do not require round-trips between XML and JSON or if you need to send a large amount of data over a network. It borrows the `$` syntax for text elements from the BadgerFish convention but attempts to avoid needless text-only JSON properties. It also does not distinguish between elements and attributes. The rules are:

*  Element names become object properties.
*  Text content of elements goes directly in the value of an object.

        <alice>bob</alice>

    becomes

        { "alice": "bob" }

*  Nested elements become nested properties.

        <alice><bob>charlie</bob><david>edgar</david></alice>

    becomes

        { "alice": { "bob": "charlie", "david": "edgar" } }

*   Multiple elements with the same name and at the same level become array elements.

        <alice><bob>charlie</bob><bob>david</bob></alice>

    becomes

        { "alice": { "bob": [ "charlie", "david" ] } }

*   Mixed content (element and text nodes) at the same level become array elements.

        <alice>bob<charlie>david</charlie>edgar</alice>

    becomes

        { "alice": [ "bob", { "charlie": "david" }, "edgar" ] }

*   Attributes go in properties.

        <alice charlie="david">bob</alice>

    becomes

        { "alice": { "charlie": "david", "$": "bob" } }

#### BadgerFish convention (use-badgerfish)

The BadgerFish convention was invented by [David Sklar](http://www.sklar.com/) ; more detailed information can be found on his [BadgerFish website](http://badgerfish.ning.com/). I have taken some liberties in supporting BadgerFish, for example the treatment of mixed content nodes (nodes with both text and element nodes as children) which was not covered in the convention (except for a mention in the to-do list) but is supported by XSLTJSON. The other change is that namespaces are optional instead of mandatory (which is also mentioned in the to-do list.) The rules are:

*   Element names become object properties.
*   Text content of elements goes in the `$` property of an object.

        <alice>bob</alice>

    becomes

        { "alice": { "$": "bob" } }

*   Nested elements become nested properties.

        <alice><bob>charlie</bob><david>edgar</david></alice>

    becomes

        { "alice": {"bob": { "$": "charlie" }, "david": { "$": "edgar" } } }

*   Multiple elements with the same name and at the same level become array elements.

        <alice><bob>charlie</bob><bob>david</bob></alice>

    becomes

        { "alice": { "bob": [ { "$": "charlie" }, { "$": "david" } ] } }

*   Mixed content (element and text nodes) at the same level become array elements.

        <alice>bob<charlie>david</charlie>edgar</alice>

    becomes

        { "alice": [ { "$": "bob" }, { "charlie": { "$": "david" } }, { "$": "edgar" } ] }

*   Attributes go in properties whose name begin with `@` .

        <alice charlie="david">bob</alice>

    becomes

        { "alice": { "@charlie": "david", "$": "bob" } }

#### RabbitFish (use-rabbitfish)

RabbitFish is identical to the basic output format except that it uses Rule 6 “Attributes go in properties whose name begin with `@`” from the BadgerFish convention in order to distinguish between elements and attributes.

#### Rayfish (use-rayfish)

The [Rayfish convention](http://onperl.org/blog/onperl/page/rayfish) was invented by [Micheal Matthew](http://onperl.org/) and aims to create highly structured JSON which is easy to parse and extract information from due to its regularity. This makes it an excellent choice for data centric XML documents. The downside is that it does not support mixed content (elements and text nodes at the same level) and is slightly more verbose than the other output formats. The rules are:

*   Elements are transformed into an object with three properties: `#name`, `#text` and `#children`. The name property contains the name of the element, the text property contains the text contents of the element and the children property contains an array of the child elements.

        <alice/>

    becomes

        { "#name": "alice", "#text": null, "#children": [ ] }

*   Nested elements become members of the `#children` property of the parent element.

        <alice><bob>charlie</bob><david>edgar</david></alice>

    becomes

        { "#name": "alice", "#text": null, "#children": [ 
            { "#name": "bob", "#text": "charlie", "#children": [ ] }, 
            { "#name": "david", "#text": "edgar", "#children": [ ] }
        ]}

*   Attributes go into an object in the `#children` property and begin with `@` .

        <alice charlie="david">bob</alice>

    becomes

        { "#name": "alice", "#text": "bob", "#children": [ 
            { "#name": "@charlie", 
              "#text": "david", 
              "#children": [ ] 
            }
        ]}

#### Namespaces (use-namespaces)

When turned on, namespaces are created according to the [BadgerFish convention](http://badgerfish.ning.com/). In basic output, the `@` is left out of the property name.

## XSLTJSON Lite (XSLT 1.0 compatible)

The [XSLTJSON Lite stylesheet](conf/xml-to-jsonml.xsl) transforms arbitrary XML to the [JSONML format](http://jsonml.org/). It is written in XSLT 1.0, so it is compatible with all XSLT 1.0 and 2.0 processors, as well as the XSLT processor built into most modern browsers (for client-side transformations.) The stylesheet doesn't take any parameters and has no configurable options. Use it like you would use any XSLT stylesheet.

## Requirements

XSLTJSON requires an XSLT 2.0 processor. An excellent option is [Saxon](http://www.saxonica.com/), which was used to test and develop XSLTJSON.

## XSLT 2.0?

Don't have an XSLT 2.0 processor? Check out [Micheal Matthew's Rayfish project](http://onperl.org/blog/onperl/page/rayfish), [xml2json](http://code.google.com/p/xml2json-xslt/), or a modified [xml2json version by Martynas Jusevičius](http://www.xml.lt/Blog/2009/01/21/XML+to+JSON). You can also use [XSLTJSON Lite](conf/xml-to-jsonml.xsl) to transform XML to JSONML.

## Credits

Thanks to: Chick Markley (Octal number & numbers with terminating period fix), Torben Schreiter (Suggestions for skip root, and newline entities bug fix), Michael Nilsson (Bug report & text cases for json:force-array.)
