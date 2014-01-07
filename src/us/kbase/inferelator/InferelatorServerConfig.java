package us.kbase.inferelator;

public class InferelatorServerConfig {
	//Deployment options
	protected static boolean DEPLOY_AWE = false;
	
	//Service URLs
	public static final String JOB_SERVICE_URL = "https://kbase.us/services/userandjobstate";//dev:"http://140.221.84.180:7083";
	public static final String AWE_SERVICE_URL = "http://140.221.85.171:7080/job";
	public static final String ID_SERVICE_URL = "http://kbase.us/services/idserver";
	public static final String WS_SERVICE_URL = "http://140.221.84.209:7058";
	public static final String SHOCK_URL = "http://140.221.84.236:8000";
	
	//Paths
	protected static final String JOB_DIRECTORY = "/var/tmp/inferelator/";
	protected static final String INFERELATOR_DIRECTORY = "/kb/runtime/cmonkey-python/inferelator/";
	protected static final String INFERELATOR_RUN_PATH = "/kb/runtime/cmonkey-python/inferelator/run_inf.R";

	//Logging options
	
	//Writes all JSON calls to AWE client and all AWE responses to /var/tmp/cmonkey/cmonkey-awe.log
	//This is a serious security threat because log will contain all auth tokens
	//SET IT TO FALSE ON PRODUCTION  
	public static final boolean LOG_AWE_CALLS = true;

}