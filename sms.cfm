<cfif thisTag.ExecutionMode eq "end">
	<cfexit/>
</cfif>

<cfparam name="attributes.username" default="" />
<cfparam name="attributes.password" default="" />
<cfparam name="attributes.from" default="" />
<cfparam name="attributes.to" default="" />
<cfparam name="attributes.body" default="" />
 
<cfset smsStruct = structnew()/>
<cfset smsStruct.username = attributes.username/>
<cfset smsStruct.password = attributes.password/>
<cfset smsStruct.from = attributes.from/>
<cfset smsStruct.to = attributes.to/>
<cfset smsStruct.body = attributes.body/>
<cfwddx action="cfml2wddx" input="#smsStruct#" output="ddx"/>
<cffile action="write" file="#server.coldfusion.rootdir#\sms\spool\#createuuid()#.sms" output="#ddx#"/>