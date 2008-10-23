<cfscript>
function getFirstWeekPAD(firstDOW) {
	var firstWeekPad=0;
	var weekStartsOn=getPlugin("i18n").weekStarts();
	switch (weekStartsON) {
		case 1:
			firstWeekPAD=firstDOW-1;
		break;
		case 2:
			firstWeekPAD=firstDOW-2;
			if (firstWeekPAD LT 0) firstWeekPAD=firstWeekPAD+7; // handle leap years
		break;
		case 7:
			firstWeekPAD=7-abs(firstDOW-7);
			if (firstWeekPAD EQ 7) firstWeekPAD=0;
		break;
	}
	return firstWeekPAD;
}
	
function toList(str) {
	str = replace(str, chr(10), "", "all");
	str = replace(str, chr(13), ",", "all");
	return str;
}
function titleCase(str) {
	return uCase(left(str,1)) & right(str,len(str)-1);
}

/**
 * Tests passed value to see if it is a valid e-mail address (supports subdomain nesting and new top-level domains).
 * Update by David Kearns to support '
 * SBrown@xacting.com pointing out regex still wasn't accepting ' correctly.
 *
 * @param str 	 The string to check. (Required)
 * @return Returns a boolean.
 * @author Jeff Guillaume (jeff@kazoomis.com)
 * @version 2, August 15, 2002
 */
function IsEmail(str) {
        //supports new top level tlds
if (REFindNoCase("^['_a-z0-9-]+(\.['_a-z0-9-]+)*@[a-z0-9-]+(\.[a-z0-9-]+)*\.(([a-z]{2,3})|(aero|coop|info|museum|name))$",str)) return TRUE;
	else return FALSE;
}

function isLoggedIn() {
	return structKeyExists(session,"loggedin");
}

/**
 * An &quot;enhanced&quot; version of ParagraphFormat.
 * Added replacement of tab with nonbreaking space char, idea by Mark R Andrachek.
 * Rewrite and multiOS support by Nathan Dintenfas.
 *
 * @param string 	 The string to format. (Required)
 * @return Returns a string.
 * @author Ben Forta (ben@forta.com)
 * @version 3, June 26, 2002
 */
function ParagraphFormat2(str) {
	//first make Windows style into Unix style
	str = replace(str,chr(13)&chr(10),chr(10),"ALL");
	//now make Macintosh style into Unix style
	str = replace(str,chr(13),chr(10),"ALL");
	//now fix tabs
	str = replace(str,chr(9),"&nbsp;&nbsp;&nbsp;","ALL");
	//now return the text formatted in HTML
	return replace(str,chr(10),"<br />","ALL");
}

/**
 * A quick way to test if a string is a URL
 *
 * @param stringToCheck 	 The string to check.
 * @return Returns a boolean.
 * @author Nathan Dintenfass (nathan@changemedia.com)
 * @version 1, November 22, 2001
 */
function isURL(stringToCheck){
		return REFindNoCase("^(((https?:|ftp:|gopher:)\/\/))[-[:alnum:]\?%,\.\/&##!@:=\+~_]+[A-Za-z0-9\/]$",stringToCheck) NEQ 0;
}
</cfscript>

<!---
	  This UDF from Steven Erat, http://www.talkingtree.com/blog
--->
<cffunction name="replaceLinks" access="public" output="yes" returntype="string">
    <cfargument name="input" required="Yes" type="string">
    <cfscript>
        var inputReturn = arguments.input;
        var pattern = "";
        var urlMatches = structNew();
        var inputCopy = arguments.input;
        var result = "";
        var rightStart = "";
        var rightInputCopyLen = "";
        var targetNameMax = "";
        var targetLinkName = "";
        var i = "";

        pattern = "(http|https|ftp)://[-\w.]+(:\d+)?(/([\w/_.\-##\+\@]*(\?\S+)?)?)?";
        while (len(inputCopy)) {
            result = refind(pattern,inputCopy,1,'true');
            if (result.pos[1]){
                match = mid(inputCopy,result.pos[1],result.len[1]);
                urlMatches[match] = "";
                rightStart = result.len[1] + result.pos[1];
                rightInputCopyLen = len(inputCopy)-rightStart;
                if (rightInputCopyLen GT 0){
                    inputCopy = right(inputCopy,rightInputCopyLen);
                } else break;
            } else break;
        }

        //convert back to array
        urlMatches = structKeyArray(urlMatches);

        targetNameMax = 50;
        for (i=1; i LTE arraylen(urlMatches);i=i+1) {
            targetLinkName = urlMatches[i];
            if (len(targetLinkName) GTE targetNameMax) {
                targetLinkName = left(targetLinkName,targetNameMax) & "...";
            }
            inputReturn = replace(inputReturn,urlMatches[i],'<a href="#urlMatches[i]#" target="_blank">#targetLinkName#</a>',"all");
        }
    </cfscript>
    <cfreturn inputReturn>
</cffunction>