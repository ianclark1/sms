<cfcomponent>
	<!---
		This should be in the config file.
		
		is there a way to read values from the cfg file?
	--->
	<cfset undeliverablePath = "C:\ColdFusion9\sms\undelivr"/>
	
	<cffunction name="send" output="false" access="private" returntype="boolean">
		<cfargument name="username" required="true" type="string"/>
		<cfargument name="password" required="true" type="string"/>
		<cfargument name="from" required="true" type="string"/>
		<cfargument name="to" required="true" type="string"/>
		<cfargument name="body" required="true" type="string"/>
		
		<cftry>
			<!--- SMS can only be 160 characters. If SMS is longer than 160, break into multiple SMS's --->
			<cfset smsArray = arraynew(1)/>
			<cfset smsstr = ""/>
			<cfloop from="1" to="#len(arguments.body)#" index="i">
				<cfset smsstr = smsstr & mid(arguments.body, i, 1)/>
				
				<cfif i mod 160 eq 0>
					<cfset arrayappend(smsArray, smsstr)/>
					<cfset smsstr = ""/>
				</cfif>
			</cfloop>
			
			<cfif len(smsstr)>
				<cfset arrayappend(smsArray, smsstr)/>
			</cfif>
			
			<cfset urlstr = "https://api.twilio.com/2010-04-01/Accounts/#arguments.username#/SMS/Messages.xml"/>
			<cfloop from="1" to="#arraylen(smsArray)#" index="i">
				<cfhttp url="#urlstr#" method="post" username="#arguments.username#" password="#arguments.password#">
					<cfhttpparam type="formfield" name="From" value="#arguments.from#"/>
					<cfhttpparam type="formfield" name="To" value="#arguments.to#"/>
					<cfhttpparam type="formfield" name="Body" value="#smsArray[i]#"/>
				</cfhttp>
				
				<cfif listfirst(cfhttp.statusCode, " ") eq 200>
					<cflog file="sms-watcher-sent" text="from=#arguments.from#, to=#arguments.to#, body=#arguments.body#" />
					<cfreturn true/>
				<cfelse>
					<cfset twilXml = xmlparse(cfhttp.filecontent)/>
					<cflog file="sms-watcher-sent" text="error=#twilXml.TwilioResponse.RestException.Message.xmltext#" />
					<cfreturn false/>
				</cfif>
			</cfloop>
			
			<cfcatch type="any">
				<cflog file="sms-watcher" text="#cfcatch.message#" />
				<cfreturn false/>
			</cfcatch>
		</cftry>
	</cffunction>
	
 	<cffunction name="onAdd" access="public" output="false" returntype="void">
	 	<cfargument name="CFEvent" type="struct" required="yes">
		 
		 <cftry>
			<cffile action="read" file="#arguments.cfevent.data.filename#" variable="ddx" />
			<cfwddx action="wddx2cfml" input="#ddx#" output="smsStruct" />
			 
			<cfset fileName = getfilefrompath(arguments.cfevent.data.filename)/>
			<cfset folderName = getdirectoryfrompath(arguments.cfevent.data.filename)/>
			
			<cffile action="move" destination="#folderName#\#listfirst(fileName, ".")#.proc" source="#arguments.cfevent.data.filename#" />
			<cfset bSend = send(smsStruct.username, smsStruct.password, smsStruct.from, smsStruct.to, smsStruct.body)/>
			
			<cfif bSend>
	 			<cffile action="delete" file="#folderName#\#listfirst(fileName, ".")#.proc" />
			<cfelse>
				<cffile action="move" destination="#undeliverablePath#\#listfirst(fileName, ".")#.sms" source="#folderName#\#listfirst(fileName, ".")#.proc" />
			</cfif>
			
			<cfcatch type="any">
				  <cflog file="sms-watcher" text="#cfcatch.message#" />
				  <cffile action="move" destination="#undeliverablePath#\#listfirst(fileName, ".")#.sms" source="#folderName#\#listfirst(fileName, ".")#.proc" />
			</cfcatch>
		 </cftry>
    </cffunction>
 
    <cffunction name="onChange" access="public" output="false" returntype="void">
    </cffunction>
 
    <cffunction name="onDelete" access="public" output="false" returntype="void">
    </cffunction>
</cfcomponent>