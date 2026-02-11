/*
*********************************************************
Apex Class Name    : CSVHeader
Created Date       : Apr 12, 2024
@description       : This APEX Class will be used to store important information about the individual columns
@author            : Mayuri Patel
Modification Log:
Ver   Date         Author                  Modification
1.0   12-04-2024   Mayuri Patel            Initial Version
*********************************************************
*/
public class CSVHeader  {

    @AuraEnabled
    public String object_name {get; set;}
    
    @AuraEnabled
    public String column_name {get; set;}
    
     @AuraEnabled
    public String column_api_name {get; set;}

    @AuraEnabled
    public String column_type{get; set;}
    
    public CSVHeader(){}
    
    public CSVHeader(String column_name, String api_name, String object_name, DataType column_type) {
        this.column_name = column_name;
        this.column_type = String.valueOf(column_type);
        this.object_name = object_name;
        this.column_api_name = api_name;      
       // system.debug(this.column_type);
    } 

    public CSVHeader(String column_name, String api_name, String object_name) {
        this.column_name = column_name;
        this.object_name = object_name;
        this.column_api_name = api_name;
    }
    public static DataType toDataType(String s) {
        for (DataType m : DataType.values()) {
           // system.debug(m + s); 
            if (m.name() == s) return m;
        }
        return null;
    }
}