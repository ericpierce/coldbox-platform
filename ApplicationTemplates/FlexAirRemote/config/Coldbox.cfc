<cfcomponent output="false" hint="My App Configuration">
<cfscript>
/**
structures to create for configuration

- coldbox
- settings
- conventions
- environments
- ioc
- models
- debugger
- mailSettings
- i18n
- bugTracers
- webservices
- datasources
- layoutSettings
- layouts
- cacheEngine
- interceptorSettings
- interceptors

Available objects in variable scope
- controller
- logBoxConfig
- appMapping (auto calculated by ColdBox)

Required Methods
- configure() : The method ColdBox calls to configure the application.
Optional Methods
- detectEnvironment() : If declared the framework will call it and it must return the name of the environment you are on.
- {environment}() : The name of the environment found and called by the framework.

*/
	
// Configure ColdBox Application
function configure(){

	// coldbox directives
	coldbox = {
		//Application Setup
		appName 				= "Your App Name Here",
		//eventName 				= "event",
		
		//Development Settings
		debugMode				= true,
		debugPassword			= "",
		reinitPassword			= "",
		handlersIndexAutoReload = true,
		configAutoReload		= false,
		
		//Implicit Events
		defaultEvent			= "general.index",
		requestStartHandler		= "",
		requestEndHandler		= "",
		applicationStartHandler = "main.onAppInit",
		applicationEndHandler	= "",
		sessionStartHandler 	= "",
		sessionEndHandler		= "",
		missingTemplateHandler	= "",
		
		//Extension Points
		UDFLibraryFile 			= "",
		coldboxExtensionsLocation = "",
		pluginsExternalLocation = "",
		viewsExternalLocation	= "",
		layoutsExternalLocation = "",
		handlersExternalLocation  = "",
		requestContextDecorator = "",
		
		//Error/Exception Handling
		exceptionHandler		= "",
		onInvalidEvent			= "",
		customErrorTemplate		= "",
			
		//Application Aspects
		handlerCaching 			= false,
		eventCaching			= false,
		proxyReturnCollection 	= false,
		flashURLPersistScope	= "session"
	};
	
	// environment settings, create a detectEnvironment() method to detect it yourself.
	// create a function with the name of the environment so it can be executed if that environment is detected
	// the value of the environment is a list of regex patterns to match the cgi.http_host.
	environments = {
		//development = "^cf8.,^railo."
	};
	
	// custom settings
	settings = {
	
	};
	
	//Model Integration
	models = {
		definitionFile = "config/modelMappings.cfm"
		//objectCaching = true,
		//externalLocation = "coldbox.testing.testmodel",
		//SetterInjection = false,
		//DICompleteUDF = "onDIComplete",
		//StopRecursion = "",
	};
	
	//Conventions
	conventions = {
		handlersLocation = "monitor/handlers",
		viewsLocation = "monitor/views",
		layoutsLocation = "monitor/layouts"
	};
	

	//Layout Settings
	layoutSettings = {
		defaultLayout = "Layout.Main.cfm"
	};
	
	//Register interceptors as an array, we need order
	interceptors = [
		 //Autowire
		 {class="coldbox.system.interceptors.Autowire"}
	];
	
	//LogBox
	logBoxConfig.appender(name="coldboxTracer",class="coldbox.system.logging.appenders.ColdboxTracerAppender");
	logBoxConfig.root(levelMax=logBoxConfig.logLevels.INFO,appenders="*");
	logBoxConfig.info("coldbox.system");
	
}
	
</cfscript>
</cfcomponent>