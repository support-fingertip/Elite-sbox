/*
*********************************************************
Apex Class Name    : CSVObject
Created Date       : Apr 12, 2024
@description       : This APEX Class will be used to store the imported CSV data
@author            : Mayuri Patel
Modification Log:
Ver   Date         Author                  Modification
1.0   12-04-2024   Mayuri Patel            Initial Version
*********************************************************
*/
public class CSVObject  {

    @AuraEnabled
    public List<CSVHeader> headers {get; set;}

    @AuraEnabled
    public List<List<String>> lines {get; set;}

    @AuraEnabled
    public Integer line_count {get; set;}

    public CSVObject() {}

    public CSVObject(List<CSVHeader> headers, List<List<String>> lines) {
        this.headers = headers;
        this.lines = lines;
        this.line_count = lines.size();
    }

}