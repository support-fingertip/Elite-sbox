/*
*********************************************************
Apex Class Name    : ExceptionHandler
Created Date       : Mar 15, 2024
@description       : This class is used to create Error Logs for any DML statements
@author            : Mayuri Patel
Modification Log:
Ver   Date         Author                  Modification
1.0   15-03-2024   Mayuri Patel            Initial Version
*********************************************************
*/
public class ExceptionHandler {
    
       /*
    *********************************************************
    @Method Name    : addLog
	@Created Date   : Mar 15, 2024
    @author         : Mayuri Patel
    @description    : This method is used to create a log with Exception details and record data
    @param          : ae:- Exception Details, data:- Record data as JSON string
    @return         : NA
    ********************************************************
    */
    public static void addLog(Exception ae,String data){
        Error_Log__c err = new Error_Log__c();
        err.LineNumber__c = ae.getLineNumber();
        err.Message__c = ae.getMessage();
        err.StackTrace__c = ae.getStackTraceString();
        err.Type__c = ae.getTypeName();
        err.User__c = UserInfo.getUserId();
        err.RecordData__c = data;
        database.insert(err,false);  
    }
     /*
    *********************************************************
    @Method Name    : addLog
	@Created Date   : Mar 15, 2024
    @author         : Mayuri Patel
    @description    : This method is used to create a log with Exception details and record data with class/controller name
    @param          : ae:- Exception Details, data:- Record data as JSON string, className:- name of the apex class
    @return         : NA
    ********************************************************
    */
    public static void addLog(Exception ae,String data, String className){
        Error_Log__c err = new Error_Log__c();
        err.LineNumber__c = ae.getLineNumber();
        err.Message__c = ae.getMessage();
        err.StackTrace__c = ae.getStackTraceString();
        err.Type__c = ae.getTypeName();
        err.User__c = UserInfo.getUserId();
        err.RecordData__c = data;
        err.ClassName__c = className;
        database.insert(err,false);  
    }
    /*
    *********************************************************
    @Method Name    : addLog
	@Created Date   : Mar 15, 2024
    @author         : Mayuri Patel
    @description    : This method is used to create a log with passed details 
    @param          : line:- Line Number, msg:- Error Msg, str:- stacktrace, typ:- Error Type, data:- Record data as JSON string
    @return         : NA
    ********************************************************
    */
    public static void addLog(Integer line,String msg,String str,String typ,String data, String className){
        Error_Log__c err = new Error_Log__c();
        err.LineNumber__c = line;
        err.Message__c = msg;
        err.StackTrace__c = str;
        err.Type__c = typ;
        err.User__c = UserInfo.getUserId();
        err.RecordData__c = data;
         err.ClassName__c = className;
        database.insert(err,false);  
    }
    /*
    *********************************************************
    @Method Name    : addLog
	@Created Date   : Mar 15, 2024
    @author         : Mayuri Patel
    @description    : This method is used to create a log with Exception details
    @param          : ae:- Exception Details
    @return         : NA
    ********************************************************
    */
    public static void addLog(Exception ae){
        Error_Log__c err = new Error_Log__c();
        err.LineNumber__c = ae.getLineNumber();
        err.Message__c = ae.getMessage();
        err.StackTrace__c = ae.getStackTraceString();
        err.Type__c = ae.getTypeName();
        err.User__c = UserInfo.getUserId();
        database.insert(err,false);  
    }
}