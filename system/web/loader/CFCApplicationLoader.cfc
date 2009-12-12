<!-----------------------------------------------------------------------
********************************************************************************
Copyright 2005-2008 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
www.coldboxframework.com | www.luismajano.com | www.ortussolutions.com
********************************************************************************

Author 	 		: Luis Majano
Date     		: September 23, 2005
Description		: 

Loads a coldbox xml configuration file

----------------------------------------------------------------------->
<cfcomponent hint="Loads a coldbox xml configuration file" output="false" extends="coldbox.system.web.loader.AbstractApplicationLoader">

<!------------------------------------------- CONSTRUCTOR ------------------------------------------>
	
	<cfscript>
		instance = structnew();
	</cfscript>

	<!--- init --->
	<cffunction name="init" output="false" access="public" returntype="any" hint="constructor">
		<cfargument name="controller" 			type="any" 		required="true" default="" hint="The coldbox application to load the settings into"/>
		<cfscript>
			super.init(arguments.controller);
			
			return this;
		</cfscript>
	</cffunction>

<!------------------------------------------- PUBLIC ------------------------------------------>
	
	<cffunction name="loadConfiguration" access="public" returntype="void" output="false" hint="Parse the application configuration file.">
		<!--- ************************************************************* --->
		<cfargument name="overrideAppMapping" required="false" type="string" default="" hint="The direct location of the application in the web server."/>
		<!--- ************************************************************* --->
		<cfscript>
		//Create Config Structure
		var configStruct = structNew();
		var coldboxSettings = getColdboxSettings();
		var appRootPath = getController().getAppRootPath();
		var configCFCLocation = getUtil().ripExtension(replacenocase(coldboxSettings["ConfigFileLocation"],appRootPath,""));
		var configCreatePath = "";
		var oConfig = "";
		var logBoxConfigHash = hash(getController().getLogBox().getConfig().getMemento().toString());
		
		//Is incoming app mapping set, or do we auto-calculate
		if( NOT len(arguments.overrideAppMapping) ){
			//AutoCalculate
			calculateAppMapping(configStruct);
		}
		else{
			configStruct.appMapping = arguments.overrideAppMapping;
		}
		
		//Default Locations for ROOT based apps, which is the default
		//Parse out the first / to create the invocation Path
		if ( left(configStruct["AppMapping"],1) eq "/" ){
			configStruct["AppMapping"] = removeChars(configStruct["AppMapping"],1,1);
		}
		//AppMappingInvocation Path
		appMappingAsDots = reReplace(configStruct["AppMapping"],"(/|\\)",".","all");
		//Config Create Path
		if( len(appMappingAsDots) ){
			configCreatePath = appMappingAsDots & "." & configCFCLocation;
		}
		else{
			configCreatePath = configCFCLocation;
		}
		
		//Create config Object
		oConfig = createObject("component", configCreatePath);
		
		//Decorate It
		oConfig.injectPropertyMixin = variables.injectPropertyMixin;
		oConfig.getPropertyMixin 	= variables.getPropertyMixin;
		
		//MixIn Variables
		oConfig.injectPropertyMixin("controller",getController());
		oConfig.injectPropertyMixin("logBoxConfig",getController().getLogBox().getConfig());
		oConfig.injectPropertyMixin("appMapping",configStruct.appMapping);
		
		//Configure it
		oConfig.configure();
		
		//Environment detection
		detectEnvironment(oConfig,configStruct);
		 
		/* ::::::::::::::::::::::::::::::::::::::::: APP LOCATION CALCULATIONS :::::::::::::::::::::::::::::::::::::::::::: */
		
		// load default application paths
		loadApplicationPaths(configStruct,arguments.overrideAppMapping);
		
		/* ::::::::::::::::::::::::::::::::::::::::: GET COLDBOX SETTINGS  :::::::::::::::::::::::::::::::::::::::::::: */
		parseColdboxSettings(oConfig,configStruct,arguments.overrideAppMapping);
		
		/* ::::::::::::::::::::::::::::::::::::::::: YOUR SETTINGS LOADING :::::::::::::::::::::::::::::::::::::::::::: */
		parseYourSettings(oConfig,configStruct);	
		
		/* ::::::::::::::::::::::::::::::::::::::::: YOUR CONVENTIONS LOADING :::::::::::::::::::::::::::::::::::::::::::: */
		parseConventions(oConfig,configStruct);
		
		/* ::::::::::::::::::::::::::::::::::::::::: MODEL SETTINGS  :::::::::::::::::::::::::::::::::::::::::::: */
		parseModels(oConfig,configStruct);
		
		/* ::::::::::::::::::::::::::::::::::::::::: IOC SETTINGS  :::::::::::::::::::::::::::::::::::::::::::: */
		parseIOC(oConfig,configStruct);
		
		/* ::::::::::::::::::::::::::::::::::::::::: HANDLER-MODELS-PLUGIN INVOCATION PATHS :::::::::::::::::::::::::::::::::::::::::::: */
		parseInvocationPaths(oConfig,configStruct);
		
		/* ::::::::::::::::::::::::::::::::::::::::: EXTERNAL LAYOUTS/VIEWS LOCATION :::::::::::::::::::::::::::::::::::::::::::: */
		parseExternalLocations(oConfig,configStruct);
		
		/* ::::::::::::::::::::::::::::::::::::::::: MAIL SETTINGS :::::::::::::::::::::::::::::::::::::::::::: */
		parseMailSettings(oConfig,configStruct);	
		
		/* ::::::::::::::::::::::::::::::::::::::::: I18N SETTINGS :::::::::::::::::::::::::::::::::::::::::::: */
		parseLocalization(oConfig,configStruct);			
		
		/* ::::::::::::::::::::::::::::::::::::::::: BUG MAIL SETTINGS :::::::::::::::::::::::::::::::::::::::::::: */
		parseBugTracers(oConfig,configStruct);			
		
		/* ::::::::::::::::::::::::::::::::::::::::: WS SETTINGS :::::::::::::::::::::::::::::::::::::::::::: */
		parseWebservices(oConfig,configStruct);			

		/* ::::::::::::::::::::::::::::::::::::::::: DATASOURCES SETTINGS :::::::::::::::::::::::::::::::::::::::::::: */
		parseDatasources(oConfig,configStruct);
		
		/* ::::::::::::::::::::::::::::::::::::::::: LAYOUT VIEW FOLDER SETTINGS :::::::::::::::::::::::::::::::::::::::::::: */
		parseLayoutsViews(oConfig,configStruct);			
		
		/* :::::::::::::::::::::::::::::::::::::::::  CACHE SETTINGS :::::::::::::::::::::::::::::::::::::::::::: */
		parseCacheSettings(oConfig,configStruct);
					
		/* ::::::::::::::::::::::::::::::::::::::::: DEBUGGER SETTINGS :::::::::::::::::::::::::::::::::::::::::::: */
		parseDebuggerSettings(oConfig,configStruct);			
					
		/* ::::::::::::::::::::::::::::::::::::::::: INTERCEPTOR SETTINGS :::::::::::::::::::::::::::::::::::::::::::: */
		parseInterceptors(oConfig,configStruct);
		
		/* ::::::::::::::::::::::::::::::::::::::::: LOGBOX Configuration :::::::::::::::::::::::::::::::::::::::::::: */
		parseLogBox(configStruct,logBoxConfigHash);
		
		/* ::::::::::::::::::::::::::::::::::::::::: CONFIG FILE LAST MODIFIED SETTING :::::::::::::::::::::::::::::::::::::::::::: */
		configStruct.configTimeStamp = getUtil().fileLastModified(coldboxSettings["ConfigFileLocation"]);
		
		//finish by loading configuration
		getController().setConfigSettings(configStruct);
		</cfscript>
	</cffunction>
	
	<!--- parseColdboxSettings --->
	<cffunction name="parseColdboxSettings" output="false" access="public" returntype="void" hint="Parse ColdBox Settings">
		<cfargument name="oConfig" 				type="any" 		required="true" hint="The config object"/>
		<cfargument name="config" 				type="struct" 	required="true" hint="The config struct"/>
		<cfargument name="overrideAppMapping" required="false" type="string" default="" hint="The direct location of the application in the web server."/>
		<cfscript>
			var configStruct = arguments.config;
			var fwSettingsStruct = getColdboxSettings();
			var coldboxSettings = arguments.oConfig.getPropertyMixin("coldbox","variables",structnew());
			
			// check if settings are available
			if( structIsEmpty(coldboxSettings) ){
				getUtil().throwit(message="ColdBox settings empty, cannot continue",type="CFCApplicationLoader.ColdBoxSettingsEmpty");
			}
			
			// collection append
			structAppend(configStruct,coldboxSettings,true);
			
			/* ::::::::::::::::::::::::::::::::::::::::: COLDBOX SETTINGS VALIDATION :::::::::::::::::::::::::::::::::::::::::::: */
			
			// Default environment setting.
			configStruct.environment = "PRODUCTION";
			
			//Check for AppName or throw
			if ( not StructKeyExists(configStruct, "AppName") )
				getUtil().throwit("There was no 'AppName' setting defined. This is required by the framework.","","XMLApplicationLoader.ConfigXMLParsingException");
			//Check for Default Event
			if ( not StructKeyExists(configStruct, "DefaultEvent") )
				getUtil().throwit("There was no 'DefaultEvent' setting defined. This is required by the framework.","","XMLApplicationLoader.ConfigXMLParsingException");
			//Check for Event Name
			if ( not StructKeyExists(configStruct, "EventName") )
				configStruct["EventName"] = fwSettingsStruct["EventName"] ;
			//Check for Application Start Handler
			if ( not StructKeyExists(configStruct, "ApplicationStartHandler") )
				configStruct["ApplicationStartHandler"] = "";
			//Check for Application End Handler
			if ( not StructKeyExists(configStruct, "ApplicationEndHandler") )
				configStruct["applicationEndHandler"] = "";
			//Check for Request End Handler
			if ( not StructKeyExists(configStruct, "RequestStartHandler") )
				configStruct["RequestStartHandler"] = "";
			//Check for Application Start Handler
			if ( not StructKeyExists(configStruct, "RequestEndHandler") )
				configStruct["RequestEndHandler"] = "";
			//Check for Session Start Handler
			if ( not StructKeyExists(configStruct, "SessionStartHandler") )
				configStruct["SessionStartHandler"] = "";
			//Check for Session End Handler
			if ( not StructKeyExists(configStruct, "SessionEndHandler") )
				configStruct["SessionEndHandler"] = "";
			//Check for InvalidEventHandler
			if ( not StructKeyExists(configStruct, "onInvalidEvent") )
				configStruct["onInvalidEvent"] = "";
			//Check For DebugMode in settings
			if ( not structKeyExists(configStruct, "DebugMode") or not isBoolean(configStruct.DebugMode) )
				configStruct["DebugMode"] = "false";
			//Check for DebugPassword in settings, else leave blank.
			if ( not structKeyExists(configStruct, "DebugPassword") )
				configStruct["DebugPassword"] = "";
			//Check for ReinitPassword
			if ( not structKeyExists(configStruct, "ReinitPassword") )
				configStruct["ReinitPassword"] = "";
			//Check For UDFLibraryFile
			if ( not StructKeyExists(configStruct, "UDFLibraryFile") )
				configStruct["UDFLibraryFile"] = "";
			//Check For CustomErrorTemplate
			if ( not StructKeyExists(configStruct, "CustomErrorTemplate") )
				configStruct["CustomErrorTemplate"] = "";
			//Check for HandlersIndexAutoReload, default = false
			if ( not structkeyExists(configStruct, "HandlersIndexAutoReload") or not isBoolean(configStruct.HandlersIndexAutoReload) )
				configStruct["HandlersIndexAutoReload"] = false;
			//Check for ConfigAutoReload
			if ( not structKeyExists(configStruct, "ConfigAutoReload") or not isBoolean(configStruct.ConfigAutoReload) )
				configStruct["ConfigAutoReload"] = false;
			//Check for ExceptionHandler if found
			if ( not structkeyExists(configStruct, "ExceptionHandler") )
				configStruct["ExceptionHandler"] = "";
			//Check for PluginsExternalLocation if found
			if ( not structkeyExists(configStruct, "PluginsExternalLocation") )
				configStruct["PluginsExternalLocation"] = "";
			//Check for Handler Caching
			if ( not structKeyExists(configStruct, "HandlerCaching") or not isBoolean(configStruct.HandlerCaching) )
				configStruct["HandlerCaching"] = true;
			//Check for Event Caching
			if ( not structKeyExists(configStruct, "EventCaching") or not isBoolean(configStruct.EventCaching) )
				configStruct["EventCaching"] = true;
			//RequestContextDecorator
			if ( not structKeyExists(configStruct, "RequestContextDecorator") or len(configStruct["RequestContextDecorator"]) eq 0 ){
				configStruct["RequestContextDecorator"] = "";
			}
			//Check for ProxyReturnCollection
			if ( not structKeyExists(configStruct, "ProxyReturnCollection") or not isBoolean(configStruct.ProxyReturnCollection) )
				configStruct["ProxyReturnCollection"] = false;
			//Check for External Handlers Location
			if ( not structKeyExists(configStruct, "HandlersExternalLocation") or len(configStruct["HandlersExternalLocation"]) eq 0 )
				configStruct["HandlersExternalLocation"] = "";
			// Flash URL Persist Scope Override
			if( structKeyExists(configStruct,"FlashURLPersistScope") ){
				fwSettingsStruct["FlashURLPersistScope"] = configStruct["FlashURLPersistScope"];
			}
			//Check for Missing Template Handler
			if ( not StructKeyExists(configStruct, "MissingTemplateHandler") )
				configStruct["MissingTemplateHandler"] = "";
			// Check for ColdBox Extensions Location, else use framework default.
			if( not structKeyExists(configStruct, "ColdBoxExtensionsLocation") OR not len(configStruct.ColdBoxExtensionsLocation) ){
				configStruct["ColdBoxExtensionsLocation"] = fwSettingsStruct.ColdBoxExtensionsLocation;
			}
		</cfscript>
	</cffunction>
	
	<!--- parseYourSettings --->
	<cffunction name="parseYourSettings" output="false" access="public" returntype="void" hint="Parse Your Settings">
		<cfargument name="oConfig" 	type="any" 	  required="true" hint="The config object"/>
		<cfargument name="config" 	type="struct" required="true" hint="The config struct"/>
		<cfscript>
			var configStruct = arguments.config;
			var settings = arguments.oConfig.getPropertyMixin("settings","variables",structnew());
			
			//append it
			structAppend(configStruct,settings,true);
		</cfscript>
	</cffunction>
	
	<!--- parseConventions --->
	<cffunction name="parseConventions" output="false" access="public" returntype="void" hint="Parse Conventions">
		<cfargument name="oConfig" 	type="any" 	  required="true" hint="The config object"/>
		<cfargument name="config" 	type="struct" required="true" hint="The config struct"/>
		<cfscript>
			var configStruct = arguments.config;
			var fwSettingsStruct = getColdboxSettings();
			var conventions = arguments.oConfig.getPropertyMixin("conventions","variables",structnew());
			
			// Override conventions on a per found basis.
			if( structKeyExists(conventions,"handlersLocation") ){ fwSettingsStruct["handlersConvention"] = trim(conventions.handlersLocation); }
			if( structKeyExists(conventions,"pluginsLocation") ){ fwSettingsStruct["pluginsConvention"] = trim(conventions.pluginsLocation); }
			if( structKeyExists(conventions,"layoutsLocation") ){ fwSettingsStruct["LayoutsConvention"] = trim(conventions.layoutsLocation); }
			if( structKeyExists(conventions,"viewsLocation") ){ fwSettingsStruct["ViewsConvention"] = trim(conventions.viewsLocation); }
			if( structKeyExists(conventions,"eventAction") ){ fwSettingsStruct["eventAction"] = trim(conventions.eventAction); }
			if( structKeyExists(conventions,"modelsLocation") ){ fwSettingsStruct["ModelsConvention"] = trim(conventions.modelsLocation); }
		</cfscript>
	</cffunction>

	<!--- parseModels --->
	<cffunction name="parseModels" output="false" access="public" returntype="void" hint="Parse Models">
		<cfargument name="oConfig"    type="any" 	  required="true" hint="The config object"/>
		<cfargument name="config" 	  type="struct"  required="true" hint="The config struct"/>
		<cfscript>
			var configStruct = arguments.config;
			var fwSettingsStruct = getColdBoxSettings();
			var models = arguments.oConfig.getPropertyMixin("models","variables",structnew());
			
			// Defaults if not overriding
			configStruct.ModelsExternalLocation = "";
			configStruct.ModelsObjectCaching = fwSettingsStruct["ModelsObjectCaching"];
			configStruct.ModelsDebugMode = fwSettingsStruct["ModelsDebugMode"];
			configStruct.ModelsSetterInjection = fwSettingsStruct["ModelsSetterInjection"];
			configStruct.ModelsDICompleteUDF = fwSettingsStruct["ModelsDICompleteUDF"];
			configStruct.ModelsStopRecursion = fwSettingsStruct["ModelsStopRecursion"];
			configStruct.ModelsDefinitionFile = fwSettingsStruct["ModelsDefinitionFile"];
			
			//Check for Models External Location
			if ( structKeyExists(models, "ExternalLocation") AND len(models.ExternalLocation)){
				configStruct["ModelsExternalLocation"] = models.ExternalLocation;
			}		
						
			//Check for Models ObjectCaching
			if ( structKeyExists(models, "ObjectCaching") AND isBoolean(models.ObjectCaching) ){
				configStruct["ModelsObjectCaching"] = models.ObjectCaching;
			}
			
			//Check for ModelsDebugMode
			if ( structKeyExists(models, "DebugMode") AND isBoolean(models.DebugMode) ){
				configStruct["ModelsDebugMode"] = models.DebugMode;
			}
			
			//Check for ModelsSetterInjection
			if ( structKeyExists(models, "SetterInjection") AND isBoolean(models.SetterInjection) ){
				configStruct["ModelsSetterInjection"] = models.SetterInjection;
			}
			
			//Check for ModelsDICompleteUDF
			if ( structKeyExists(models, "DICompleteUDF") AND len(models.DICompleteUDF) ){
				configStruct["ModelsDICompleteUDF"] =models.DICompleteUDF;
			}
			
			//Check for ModelsStopRecursion
			if ( structKeyExists(models, "StopRecursion") AND len(models.StopRecursion) ){
				configStruct["ModelsStopRecursion"] = models.StopRecursion;
			}
			
			//Check for ModelsDefinitionFile
			if ( structKeyExists(models, "DefinitionFile") AND len(models.DefinitionFile) ){
				configStruct["ModelsDefinitionFile"] = models.DefinitionFile;
			}
		</cfscript>
	</cffunction>
	
	<!--- parseIOC --->
	<cffunction name="parseIOC" output="false" access="public" returntype="void" hint="Parse IOC Integration">
		<cfargument name="oConfig" 	type="any" 	  required="true" hint="The config object"/>
		<cfargument name="config" 	  type="struct"  required="true" hint="The config struct"/>
		<cfscript>
			var configStruct = arguments.config;
			var fwSettingsStruct = getColdBoxSettings();
			var ioc = arguments.oConfig.getPropertyMixin("ioc","variables",structnew());
			
			//defaults
			configStruct.IOCFramework = "";
			configStruct.IOCFrameworkReload = false;
			configStruct.IOCDefinitionFile = "";
			configStruct.IOCObjectCaching = false;
			configStruct.IOCParentFactory = "";
			configStruct.IOCParentFactoryDefinitionFile = "";
			
			//Check for IOC Framework
			if ( structKeyExists(ioc, "framework") ){
				configStruct["IOCFramework"] = ioc.framework;
				configStruct["IOCDefinitionFile"] = ioc.definitionFile;
				
				if( structKeyExists(ioc,"reload") ){
					configStruct["IOCFrameworkReload"] = ioc.reload;
				}
				if( structKeyExists(ioc,"objectCaching") ){
					configStruct["IOCObjectCaching"] = ioc.objectCaching;
				}
				
			}
			
			// Parent Factory
			if ( structKeyExists(ioc, "ParentFactory") ){
				configStruct["IOCParentFactoryDefinitionFile"] = ioc.parentFactory.definitionFile;
				configStruct["IOCParentFactory"] = ioc.parentFactory.framework;
			}	
		</cfscript>
	</cffunction>
	
	<!--- parseInvocationPaths --->
	<cffunction name="parseInvocationPaths" output="false" access="public" returntype="void" hint="Parse Invocation paths">
		<cfargument name="oConfig" 	type="any" 	  required="true" hint="The config object"/>
		<cfargument name="config" 	type="struct" required="true" hint="The config struct"/>
		<cfscript>
			var configStruct = arguments.config;
			var fwSettingsStruct = getColdBoxSettings();
			var appMappingAsDots = "";
			
			// Handler Registration
			configStruct["HandlersInvocationPath"] = reReplace(fwSettingsStruct.handlersConvention,"(/|\\)",".","all");
			configStruct["HandlersPath"] = fwSettingsStruct.ApplicationPath & fwSettingsStruct.handlersConvention;
			// Custom Plugins Registration
			configStruct["MyPluginsInvocationPath"] = reReplace(fwSettingsStruct.pluginsConvention,"(/|\\)",".","all");
			configStruct["MyPluginsPath"] = fwSettingsStruct.ApplicationPath & fwSettingsStruct.pluginsConvention;
			// Models Registration
			configStruct["ModelsInvocationPath"] = reReplace(fwSettingsStruct.ModelsConvention,"(/|\\)",".","all");
			configStruct["ModelsPath"] = fwSettingsStruct.ApplicationPath & fwSettingsStruct.ModelsConvention;
			
			//Set the Handlers,Models, & Custom Plugin Invocation & Physical Path for this Application
			if( len(configStruct["AppMapping"]) ){
				appMappingAsDots = reReplace(configStruct["AppMapping"],"(/|\\)",".","all");
				// Handler Path Registrations
				configStruct["HandlersInvocationPath"] = appMappingAsDots & ".#reReplace(fwSettingsStruct.handlersConvention,"(/|\\)",".","all")#";
				configStruct["HandlersPath"] = "/" & configStruct.AppMapping & "/#fwSettingsStruct.handlersConvention#";
				configStruct["HandlersPath"] = expandPath(configStruct["HandlersPath"]);
				// Custom Plugins Registrations
				configStruct["MyPluginsInvocationPath"] = appMappingAsDots & ".#reReplace(fwSettingsStruct.pluginsConvention,"(/|\\)",".","all")#";
				configStruct["MyPluginsPath"] = "/" & configStruct.AppMapping & "/#fwSettingsStruct.pluginsConvention#";
				configStruct["MyPluginsPath"] = expandPath(configStruct["MyPluginsPath"]);
				// Model Registrations
				configStruct["ModelsInvocationPath"] = appMappingAsDots & ".#reReplace(fwSettingsStruct.ModelsConvention,"(/|\\)",".","all")#";
				configStruct["ModelsPath"] = "/" & configStruct.AppMapping & "/#fwSettingsStruct.ModelsConvention#";
				configStruct["ModelsPath"] = expandPath(configStruct["ModelsPath"]);
			}
			
			//Set the Handlers External Configuration Paths
			configStruct["HandlersExternalLocationPath"] = "";
			if( len(configStruct["HandlersExternalLocation"]) ){
				//Expand the external location to get a registration path
				configStruct["HandlersExternalLocationPath"] = ExpandPath("/" & replace(configStruct["HandlersExternalLocation"],".","/","all"));
			}
		</cfscript>
	</cffunction>

	<!--- parseExternalLocations --->
	<cffunction name="parseExternalLocations" output="false" access="public" returntype="void" hint="Parse External locations">
		<cfargument name="oConfig" 	type="any" 	  required="true" hint="The config object"/>
		<cfargument name="config" 	type="struct" required="true" hint="The config struct"/>
		<cfscript>
			var configStruct = arguments.config;
			var fwSettingsStruct = getColdBoxSettings();
			
			// ViewsExternalLocation Setup 
			if( structKeyExists(configStruct,"ViewsExternalLocation") and len(configStruct["ViewsExternalLocation"]) ){
				// Verify the locations, do relative to the app mapping first 
				if( directoryExists(fwSettingsStruct.ApplicationPath & configStruct["ViewsExternalLocation"]) ){
					configStruct["ViewsExternalLocation"] = "/" & configStruct["AppMapping"] & "/" & configStruct["ViewsExternalLocation"];
				}
				else if( not directoryExists(expandPath(configStruct["ViewsExternalLocation"])) ){
					getUtil().throwIt("ViewsExternalLocation could not be found.","The directories tested was relative and expanded using #configStruct['ViewsExternalLocation']#. Please verify your setting.","XMLApplicationLoader.ConfigXMLParsingException");
				}
				// Cleanup 
				if ( right(configStruct["ViewsExternalLocation"],1) eq "/" ){
					 configStruct["ViewsExternalLocation"] = left(configStruct["ViewsExternalLocation"],len(configStruct["ViewsExternalLocation"])-1);
				}
			}
			else{
				configStruct["ViewsExternalLocation"] = "";
			}
			
			// LayoutsExternalLocation Setup
			if( structKeyExists(configStruct,"LayoutsExternalLocation") and configStruct["LayoutsExternalLocation"] neq "" ){
				// Verify the locations, do relative to the app mapping first
				if( directoryExists(fwSettingsStruct.ApplicationPath & configStruct["LayoutsExternalLocation"]) ){
					configStruct["LayoutsExternalLocation"] = "/" & configStruct["AppMapping"] & "/" & configStruct["LayoutsExternalLocation"];
				}
				else if( not directoryExists(expandPath(configStruct["LayoutsExternalLocation"])) ){
					getUtil().throwIt("LayoutsExternalLocation could not be found.","The directories tested was relative and expanded using #configStruct['LayoutsExternalLocation']#. Please verify your setting.","XMLApplicationLoader.ConfigXMLParsingException");
				}
				// Cleanup
				if ( right(configStruct["LayoutsExternalLocation"],1) eq "/" ){
					 configStruct["LayoutsExternalLocation"] = left(configStruct["LayoutsExternalLocation"],len(configStruct["LayoutsExternalLocation"])-1);
				}
			}
			else{
				configStruct["LayoutsExternalLocation"] = "";
			}
		</cfscript>
	</cffunction>

	<!--- parseLocalization --->
	<cffunction name="parseMailSettings" output="false" access="public" returntype="void" hint="Parse Mail Settings">
		<cfargument name="oConfig" 	  type="any" 	  required="true" hint="The config object"/>
		<cfargument name="config" 	  type="struct"   required="true" hint="The config struct"/>
		<cfscript>
			var configStruct = arguments.config;
			var mailSettings = arguments.oConfig.getPropertyMixin("mailSettings","variables",structnew());
			
			// defaults
			configStruct.MailServer = "";
			configStruct.MailUsername = "";
			configStruct.MailPassword = "";
			configStruct.MailPort = 25;
		
			//Checks
			if ( structKeyExists(mailSettings, "server") )
				configStruct.MailServer = trim(mailSettings.server);
			
			//Mail username
			if ( structKeyExists(mailSettings, "username") )
				configStruct.MailUsername = trim(mailSettings.username);
			
			//Mail password
			if ( structKeyExists(mailSettings, "password") )
				configStruct.MailPassword = trim(mailSettings.password);
			
			//Mail Port
			if ( structKeyExists(mailSettings, "port") AND isNumeric(mailSettings.port) ){
				configStruct.MailPort = trim(mailSettings.port);
			}	
		</cfscript>
	</cffunction>

	<!--- parseLocalization --->
	<cffunction name="parseLocalization" output="false" access="public" returntype="void" hint="Parse localization">
		<cfargument name="oConfig" 	  type="any" 	  required="true" hint="The config object"/>
		<cfargument name="config" 	  type="struct"   required="true" hint="The config struct"/>
		<cfscript>
			var configStruct = arguments.config;
			var DefaultLocale = "";
			var i18n = arguments.oConfig.getPropertyMixin("i18N","variables",structnew());
			
			
			//Defaults
			configStruct.DefaultResourceBundle = "";
			configStruct.DefaultLocale = "";
			configStruct.LocaleStorage = "";
			configStruct.UnknownTranslation = "";
			configStruct["using_i18N"] = false;
			
			//Check if empty
			if ( NOT structIsEmpty(i18n) ){
				
				//Check for DefaultResourceBundle
				if ( structKeyExists(i18n, "DefaultResourceBundle") AND len(i18n.DefaultResourceBundle) ){
					configStruct["DefaultResourceBundle"] = i18n.DefaultResourceBundle;
				}
				
				//Check for DefaultResourceBundle
				if ( structKeyExists(i18n, "DefaultLocale") AND len(i18n.DefaultLocale) ){
					defaultLocale = i18n.DefaultLocale;
					configStruct["DefaultLocale"] = lcase(listFirst(DefaultLocale,"_")) & "_" & ucase(listLast(DefaultLocale,"_"));
				}
				
				//Check for LocaleStorage
				if ( structKeyExists(i18n, "LocaleStorage") AND len(i18n.LocaleStorage) ){
					configStruct["LocaleStorage"] = i18n.LocaleStorage;
					if( NOT reFindNoCase("^(session|cookie|client)$",configStruct["LocaleStorage"]) ){
						getUtil().throwit(message="Invalid local storage scope: #configStruct["localeStorage"]#",
							   			  detail="Valid scopes are session,client, cookie",
							   			  type="CFCApplicationLoader.InvalidLocaleStorage");
					}
				}
				
				//Check for UnknownTranslation
				if ( structKeyExists(i18n, "UnknownTranslation") AND len(i18n.UnknownTranslation) ){
					configStruct["UnknownTranslation"] = i18n.UnknownTranslation;
				}
				
				//set i18n
				configStruct["using_i18N"] = true;
			}
		</cfscript>
	</cffunction>

	<!--- parseBugTracers --->
	<cffunction name="parseBugTracers" output="false" access="public" returntype="void" hint="Parse bug emails">
		<cfargument name="oConfig" 	  type="any" 	  required="true" hint="The config object"/>
		<cfargument name="config" 	  type="struct"   required="true" hint="The config struct"/>
		<cfscript>
			var configStruct = arguments.config;
			var bugTracers = arguments.oConfig.getPropertyMixin("bugTracers","variables",structnew());
			
			//defaults
			configStruct.BugEmails = "";
			configStruct.EnableBugReports = false;
			configStruct.MailFrom = "";
			configStruct.CustomEmailBugReport = "";
			
			// Mail From
			if( structKeyExists(bugTracers,"MailFrom") and len(bugTracers.MailFrom) ){
				configStruct.mailFrom = bugTracers.mailfrom;
			}
			// Custom Bug Reports
			if( structKeyExists(bugTracers,"CustomEmailBugReport") and len(bugTracers.CustomEmailBugReport) ){
				configStruct.CustomEmailBugReport = bugTracers.CustomEmailBugReport;
			}
			// Enabled Bug Reports
			if( structKeyExists(bugTracers,"enabled") ){
				configStruct["EnableBugReports"] = bugTracers.enabled;
			}
			// Bug Emails
			if( structKeyExists(bugTracers,"bugEmails") ){
				configStruct["BugEmails"] = bugTracers.bugEmails;
			}
		</cfscript>
	</cffunction>

	<!--- parseWebservices --->
	<cffunction name="parseWebservices" output="false" access="public" returntype="void" hint="Parse webservices">
		<cfargument name="oConfig" 	  type="any" 	  required="true" hint="The config object"/>
		<cfargument name="config" 	type="struct" required="true" hint="The config struct"/>
		<cfscript>
			var configStruct = arguments.config;
			var key=1;
			var webservices = arguments.oConfig.getPropertyMixin("webservices","variables",structnew());
			
			// Defaults
			configStruct.webservices = structnew();
			
			for(key in webservices){
				configStruct[key] = webservices[key];
			}
		</cfscript>
	</cffunction>

	<!--- parseDatasources --->
	<cffunction name="parseDatasources" output="false" access="public" returntype="void" hint="Parse Datsources">
		<cfargument name="oConfig" 	  type="any" 	  required="true" hint="The config object"/>
		<cfargument name="config" 	type="struct" required="true" hint="The config struct"/>
		<cfscript>
			var configStruct = arguments.config;
			var datasources = arguments.oConfig.getPropertyMixin("datasources","variables",structnew());
			var key = "";
			
			// Defaults
			configStruct.datasources = structnew();
			
			//loop over datasources
			for( key in datasources ){
				if( NOT structKeyExists(datasources[key],"name") ){
					getUtil().throwit("This datasource #key# entry's name cannot be blank","","CFCApplicationLoader.DatasourceException");
				}
				// defaults
				if( structKeyExists(datasources[key],"username") ){
					datasources[key].username = "";
				}
				if( structKeyExists(datasources[key],"password") ){
					datasources[key].password = "";
				}
				if( structKeyExists(datasources[key],"dbType") ){
					datasources[key].dbType = "";
				}
				// save datasoure definition
				configStruct.datasources[key] = datasources[key];
			}
		</cfscript>
	</cffunction>

	<!--- parseLayoutsViews --->
	<cffunction name="parseLayoutsViews" output="false" access="public" returntype="void" hint="Parse Layouts And Views">
		<cfargument name="oConfig" 	type="any" 	  required="true" hint="The config object"/>
		<cfargument name="config" 	type="struct" required="true" hint="The config struct"/>
		<cfscript>
			var configStruct = arguments.config;
			var Collections = createObject("java", "java.util.Collections"); 
			var	LayoutViewStruct = Collections.synchronizedMap(CreateObject("java","java.util.LinkedHashMap").init());
			var	LayoutFolderStruct = Collections.synchronizedMap(CreateObject("java","java.util.LinkedHashMap").init());
			var key = "";
			var layoutSettings = arguments.oConfig.getPropertyMixin("layoutSettings","variables",structnew());
			var layouts = arguments.oConfig.getPropertyMixin("layouts","variables",structnew());
			var i = 1;
			
			// defaults
			configStruct.defaultLayout = "";
			configStruct.defaultView = "";
			configStruct.registeredLayouts = structnew();
			
			// Register layout settings
			structAppend(configStruct,layoutSettings);
			
			// registered layouts
			for(key in layouts){
				// register file with alias
				configStruct.registeredLayouts[key] = layouts[key].file;
				
				// register views
				for(i=1; i lte listLen(layouts[key].views); i=i+1){
					if ( not StructKeyExists(LayoutViewStruct, lcase( listGetAt(layouts[key].views,i) ) ) ){
						LayoutViewStruct[lcase( listGetAt(layouts[key].views,i) )] = layouts[key].file;
					}
				}
				
				// register folders
				for(i=1; i lte listLen(layouts[key].folders); i=i+1){
					if ( not StructKeyExists(LayoutFolderStruct, lcase( listGetAt(layouts[key].folders,i) ) ) ){
						LayoutFolderStruct[lcase( listGetAt(layouts[key].folders,i) )] = layouts[key].file;
					}
				}
				
			}
			
			// Register extra layout/view/folder combos
			configStruct.ViewLayouts = LayoutViewStruct;
			configStruct.FolderLayouts = LayoutFolderStruct;
		</cfscript>
	</cffunction>

	<!--- parseCacheSettings --->
	<cffunction name="parseCacheSettings" output="false" access="public" returntype="void" hint="Parse Cache Settings">
		<cfargument name="oConfig" 		type="any" 	   required="true" hint="The config object"/>
		<cfargument name="config" 	  	type="struct"  required="true" hint="The config struct"/>
		<cfscript>
			var configStruct = arguments.config;
			var fwSettingsStruct = getColdboxSettings();
			var cacheEngine = arguments.oConfig.getPropertyMixin("cacheEngine","variables",structnew());
			
			// Defaults
			configStruct.cacheSettings = structnew();
			configStruct.cacheSettings.objectDefaultTimeout 		  = fwSettingsStruct.cacheObjectDefaultTimeout;
			configStruct.cacheSettings.objectDefaultLastAccessTimeout = fwSettingsStruct.cacheObjectDefaultLastAccessTimeout;
			configStruct.cacheSettings.reapFrequency 				  = fwSettingsStruct.cacheObjectDefaultTimeout;
			configStruct.cacheSettings.freeMemoryPercentageThreshold  = fwSettingsStruct.cacheFreeMemoryPercentageThreshold;
			configStruct.cacheSettings.useLastAccessTimeouts 		  = fwSettingsStruct.cacheUseLastAccessTimeouts;
			configStruct.cacheSettings.evictionPolicy 				  = fwSettingsStruct.cacheEvictionPolicy;
			configStruct.cacheSettings.evictCount					  = fwSettingsStruct.cacheEvictCount;
			configStruct.cacheSettings.maxObjects					  = fwSettingsStruct.cacheMaxObjects;	
			
			//append settings
			structAppend(configStruct.cacheSettings, cacheEngine, true);
		</cfscript>
	</cffunction>	

	<!--- parsedebuggerSettings --->
	<cffunction name="parseDebuggerSettings" output="false" access="public" returntype="void" hint="Parse Debugger Settings">
		<cfargument name="oConfig" 		type="any" 	   required="true" hint="The config object"/>
		<cfargument name="config" 		type="struct"  required="true" hint="The config struct"/>
		<cfscript>
			var configStruct = arguments.config;
			var fwSettings = getColdBoxSettings();
			var debugger = arguments.oConfig.getPropertyMixin("debugger","variables",structnew());
			
			// defaults
			configStruct.debuggerSettings = structnew();
			configStruct.debuggerSettings.enableDumpVar 				= fwSettings.enableDumpVar;
			configStruct.debuggerSettings.persistentRequestProfiler 	= fwSettings.PersistentRequestProfiler;
			configStruct.debuggerSettings.maxPersistentRequestProfilers = fwSettings.maxPersistentRequestProfilers;
			configStruct.debuggerSettings.maxRCPanelQueryRows			= fwSettings.maxRCPanelQueryRows;
			configStruct.debuggerSettings.showTracerPanel 				= fwSettings.showTracerPanel;
			configStruct.debuggerSettings.expandedTracerPanel 			= fwSettings.expandedTracerPanel;
			configStruct.debuggerSettings.showInfoPanel 				= fwSettings.showInfoPanel;
			configStruct.debuggerSettings.expandedInfoPanel 			= fwSettings.expandedInfoPanel;
			configStruct.debuggerSettings.showCachePanel 				= fwSettings.showCachePanel;
			configStruct.debuggerSettings.expandedCachePanel 			= fwSettings.expandedCachePanel;
			configStruct.debuggerSettings.showRCPanel 					= fwSettings.showRCPanel;
			configStruct.debuggerSettings.expandedRCPanel				= fwSettings.expandedRCPanel;
			
			//append settings
			structAppend(configStruct.debuggerSettings, debugger, true);
		</cfscript>
	</cffunction>		
	
	<!--- parseInterceptors --->
	<cffunction name="parseInterceptors" output="false" access="public" returntype="void" hint="Parse Interceptors">
		<cfargument name="oConfig" 		type="any" 	   required="true" hint="The config object"/>
		<cfargument name="config" 		type="struct"  required="true" hint="The config struct"/>
		<cfscript>
			var configStruct = arguments.config;
			var x = 1;
			var interceptorSettings = arguments.oConfig.getPropertyMixin("interceptorSettings","variables",structnew());
			var interceptors = arguments.oConfig.getPropertyMixin("interceptors","variables",structnew());
			
			//defaults
			configStruct.interceptorConfig = structnew();
			configStruct.interceptorConfig.interceptors = arrayNew(1);
			configStruct.interceptorConfig.throwOnInvalidStates = false;
			configStruct.interceptorConfig.customInterceptionPoints = "";				
			
			//Append settings
			structAppend(configStruct.interceptorConfig,interceptorSettings,true);

			//Register interceptors
			for(x=1; x lte arrayLen(interceptors); x=x+1){
				//Name check
				if( NOT structKeyExists(interceptors[x],"name") ){
					interceptors[x].name = listLast(interceptors[x].class,".");
				}
				//Properties check
				if( NOT structKeyExists(interceptors[x],"properties") ){
					interceptors[x].properties = structnew();
				}
				
				//Register it
				arrayAppend(configStruct.interceptorConfig.interceptors, interceptors[x]);
			}
		</cfscript>
	</cffunction>
	
	<!--- parseLogBox --->
	<cffunction name="parseLogBox" output="false" access="public" returntype="void" hint="Parse LogBox">
		<cfargument name="config" 				type="struct"  required="true" hint="The config struct"/>
		<cfargument name="logBoxConfigHash" 	type="string"  required="true"  hint="The logbox config hash"/>
		<cfscript>
			var logBoxConfig = getController().getLogBox().getConfig();
			var newConfigHash = hash(logBoxConfig.getMemento().toString());
			
			// Default
			arguments.config["LogBoxConfig"] = structnew();
			
			// Check if hash changed
			if( compare(arguments.logBoxConfigHash, newConfigHash) neq 0 ){
				//Store LogBox Configuration on settings as new config
				arguments.config["LogBoxConfig"] = logBoxConfig.getMemento();
			}
		</cfscript>
	</cffunction>

<!------------------------------------------- PRIVATE ------------------------------------------>
	
	<!--- mixin --->
	<cffunction name="injectPropertyMixin" hint="injects a property into the passed scope" access="private" returntype="void" output="false">
		<!--- ************************************************************* --->
		<cfargument name="propertyName" 	type="string" 	required="true" hint="The name of the property to inject."/>
		<cfargument name="propertyValue" 	type="any" 		required="true" hint="The value of the property to inject"/>
		<cfargument name="scope" 			type="string" 	required="false" default="variables" hint="The scope to which inject the property to."/>
		<!--- ************************************************************* --->
		<cfscript>
			"#arguments.scope#.#arguments.propertyName#" = arguments.propertyValue;
		</cfscript>
	</cffunction>

	<!--- mixin --->
	<cffunction name="getPropertyMixin" hint="gets a property" access="private" returntype="any" output="false">
		<!--- ************************************************************* --->
		<cfargument name="name" 	type="string" 	required="true" hint="The name of the property to inject."/>
		<cfargument name="scope" 	type="string" 	required="false" default="variables" hint="The scope to which inject the property to."/>
		<cfargument name="default"  type="any"      required="false" hint="Default value to return"/>
		<!--- ************************************************************* --->
		<cfscript>
			var thisScope = variables;
			if( arguments.scope eq "this"){ thisScope = this; }
			
			if( NOT structKeyExists(thisScope,arguments.name) AND structKeyExists(arguments,"default")){
				return arguments.default;
			}
			
			return thisScope[arguments.name];
		</cfscript>
	</cffunction>
	
	<cffunction name="detectEnvironment" access="private" returntype="void" hint="Detect the running environment and return the name" output="false" >
		<cfargument name="oConfig" 		type="any" 	   required="true" hint="The config object"/>
		<cfargument name="config" 		type="struct" 	required="true" hint="The config struct"/>
		<cfscript>
			var environments = arguments.oConfig.getPropertyMixin("environments","variables",structnew());
			var configStruct = arguments.config;
			var key = "";
			var i = 1;
			
			// Set default to production
			configStruct.environment = "production";
			
			// is detection custom
			if( structKeyExists(arguments.oConfig,"detectEnvironment") ){
				//detect custom environment
				configStruct.environment = arguments.oConfig.detectEnvironment();
			}
			else{
				// loop over environments and do your magic
				for(key in environments){
					// loop over patterns
					for(i=1; i lte listLen(environments[key]); i=i+1){
						if( reFindNoCase(listGetAt(environments[key],i), cgi.http_host) ){
							// set new environment
							configStruct.environment = key;
						}
					}			
				}
			}
				
			// call environment method if exists
			if( structKeyExists(arguments.oConfig,configStruct.environment) ){
				invoker(arguments.oConfig,configStruct.environment);
			}
		</cfscript>
	</cffunction>

	<!--- invoker --->
	<cffunction name="invoker" access="private" returntype="void" output="false">
		<!--- ************************************************************* --->
		<cfargument name="oConfig" 		type="any" 	   required="true" hint="The config object"/>
		<cfargument name="method" 		type="string"  required="true" hint="Name of the method to call">
		<!--- ************************************************************* --->
		<cfinvoke component="#arguments.oConfig#" method="#arguments.method#" />
	</cffunction>

</cfcomponent>