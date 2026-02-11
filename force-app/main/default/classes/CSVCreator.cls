/*
*********************************************************
Apex Class Name : CSVCreator
Created Date : Apr 12, 2024
@description : This class is used to get the CSV String coming from the uploaded CSV file on the Lightning Component and instantiating the CSVObject with the CSVHeaders, the data lines and the line count
@author : Mayuri Patel
Modification Log:
Ver Date Author Modification
1.0 12-04-2024 Mayuri Patel Initial Version
*********************************************************
*/
public class CSVCreator {
    private static List<String> separateCommas(String input){
        /* List<String> results = input.split(',(?=(?:[^\"]*\"[^\"]*\")*[^\"]*$)');
Integer startIndex = input.startsWith('"') ? 1 : 0;
for(Integer i = 0; i < results.size(); i++) {
results[i] = results[i].trim();
}
return results;*/
        Integer startIndex = input.startsWith('"') ? 1 : 0; // Check if the input starts with a quote
        // Split the input string by comma, considering quotes
        List<String> results = input.substring(startIndex).split(',(?=(?:[^\"]*\"[^\"]*\")*[^\"]*$)');
        // Trim whitespace from each result
        for(Integer i = 0; i < results.size(); i++) {
            results[i] = results[i].trim();
        }
        return results;
    }
    /*
*********************************************************
@Method Name : getCSVObject
@Created Date : Apr 12, 2024
@author : Mayuri Patel
@description : The method used to return the CSV Object instantiated is the getCSVObject, which takes one input parameter (the CSV String)
@param : csv_str:- the CSV String
@return : CSV Object
********************************************************
*/
    @AuraEnabled
    public static CSVObject getCSVObject(String csv_str, String object_name) {
        try{
            system.debug(csv_str.length());
            system.debug(Limits.getHeapSize() + '>=' + Limits.getLimitHeapSize());
            if(Limits.getHeapSize() >= Limits.getLimitHeapSize()) throw new AuraHandledException('Max size reached');
            // List<String> lines_raw = csv_str.split('\n(?=(?:[^\"]*\"[^\"]*\")*[^\"]*$)');
            // List<String> lines_raw = csv_str.split('\n');
            Utility_RowIterator r = new Utility_RowIterator(csv_str,'\n'); //Replace \n with whatever delineates your row
            List<String> lines_raw = new List<String>();
            Iterator<String> iterator = r.iterator();
            while (iterator.hasNext()) {
                lines_raw.add(iterator.next());
            }
            List<String> headers_raw = separateCommas(lines_raw[0]);
            system.debug('headers_raw:' + headers_raw);
            List<List<String>> lines = new List<List<String>>();
            List<CSVHeader> headers = new List<CSVHeader>();
            lines_raw.remove(0);
            List<Integer> indexList = new List<Integer>();
            CSVFieldMapping mapObject = new CSVFieldMapping(object_name);
            Integer i = 0;
            for(String header : headers_raw) {
                // system.debug(header);
                String api_name = mapObject.getAPIName(header.trim());
                if(api_name != null){
                    headers.add(new CSVHeader(header,api_name,object_name,mapObject.getFieldType(api_name)));
                }
                else{
                    indexList.add(i);
                }
                i = i+1;
            }
            //Handling fields with commas
            system.debug('lines_raw:' + lines_raw);
            for(String line : lines_raw) {
                List<String> line_sep = separateCommas(line);
                List<String> fields = new List<String>();
                Boolean makeCompositeField = false;
                String compositeField;
                Integer c = 0;
                Boolean lineAdd = false;
                for(String field : line_sep) {
                    // system.debug(field);
                    if(!indexList.contains(c)){
                        if (field.startsWith('"') && field.endsWith('"')) {
                            field = field.replaceAll('^\"|\"$', '');
                            fields.add(field.trim());
                        } else if (field.startsWith('"')) {
                            makeCompositeField = true;
                            compositeField = field;
                        } else if (field.endsWith('"')) {
                            compositeField += ',' + field;
                            fields.add(compositeField.trim());
                            makeCompositeField = false;
                        } else if (makeCompositeField) {
                            compositeField += ',' + field;
                        } else {
                            fields.add(field.trim());
                        }
                       
                    }
                    c = c+1;
                }
                 lines.add(fields);
            }
            if(headers.size() > 0){
                return new CSVObject(headers, lines);
            }
            else{
                AuraHandledException e = new AuraHandledException('No fields are mapped with this file and selected Object.');
                e.setMessage('No fields are mapped with this file and selected Object.');
                throw e;
            }
        }catch(exception e){
            system.debug('Error:' + e.getMessage());
            ExceptionHandler.addLog(e, csv_str, 'CSVCreator');
            return null;
        }
    }
    /*
*********************************************************
@Method Name : ImportData
@Created Date : Apr 12, 2024
@author : Mayuri Patel
@description : The method used to import the data from uploaded file in CSVObject form
@param : csvData:- the CSV Data
@return : Status of the actions performed
********************************************************
*/
    @AuraEnabled
    public static boolean ImportData(CSVObject csvData, User selectedUser){
        system.debug('csvData-->'+csvData);
      //  system.debug('selectedUser:'+ selectedUser);
        try{
            String csvStr;
            String headerStr='';
            Boolean headerDone = false;
            String objectName = csvData.headers[0].object_name;
            SObjectType sObjType = ((SObject) Type.forName(objectName).newInstance()).getSObjectType();
            CSVFieldMapping mapObject = new CSVFieldMapping(objectName);
            // Fetch describe information outside the loop
            Map<String, Schema.DescribeFieldResult> fieldDescribeMap = new Map<String, Schema.DescribeFieldResult>();
            // Retrieve the describe result for the object
            Schema.DescribeSObjectResult objectDescribe = Schema.getGlobalDescribe()
                .get(objectName)
                .getDescribe();
            system.debug('objectDescribe:' + objectDescribe);
            // Retrieve the fields map from the describe result
            Map<String, Schema.SObjectField> fieldsMap = objectDescribe.fields.getMap();
            system.debug('fieldsMap:' + fieldsMap);
            // Iterate over the keys of the fields map and retrieve describe information for each field
            for (String fieldName : fieldsMap.keySet()) {
                // Get the describe result for the field and add it to the map
                fieldDescribeMap.put(fieldName.toLowerCase(), fieldsMap.get(fieldName).getDescribe());
            }
            List<sObject> recordsToInsert = new List<sObject>();
            // system.debug(csvData.line_count);
            //system.debug(csvData.lines.size());
            Integer j = 0;
            for(List<String> line: csvData.lines){
                Integer i = 0;
                String lineStr='';
                sObject genericObject = sObjType.newSObject();
                for(CSVHeader header : csvData.headers){
                    if(i < line.size() && ( line[i] != '' && line[i] != null && line[i] != '-')){
                        switch on (header.column_type) {
                            when 'Checkbox' {
                                genericObject.put(header.column_api_name,Boolean.valueOf(line[i]));
                            }
                            when 'DateType' {
                                String[] dt;
                                if(line[i].contains('-')){
                                    dt = line[i].split('-');
                                }
                                if(line[i].contains('/')){
                                    dt = line[i].split('/');
                                }
                                Date formattedDate = (dt != null) ? Date.valueOf(dt[2] + '-' + dt[1] + '-' + dt[0]) : Date.valueOf(line[i]) ;
                                genericObject.put(header.column_api_name,formattedDate);
                            }
                            when 'DateTimeType' {
                                String[] dt;
                                if(line[i].contains('-')){
                                    dt = line[i].split('-');
                                }
                                if(line[i].contains('/')){
                                    dt = line[i].split('/');
                                }
                                system.debug('dt'+dt);
                                Date formattedDate = Date.valueOf(dt[2] + '-' + dt[1] + '-' + dt[0]) ;
                                
                                Datetime formatTime = formattedDate;
                                genericObject.put(header.column_api_name,formatTime);
                            }
                            when 'DecimalType' {
                                genericObject.put(header.column_api_name,Decimal.valueOf(line[i]));
                            }
                            when 'IntegerType' {
                                genericObject.put(header.column_api_name,Integer.valueOf(line[i]));
                            }
                            when 'Reference' {
                                String extIdFieldName = mapObject.getExternalFieldName(header.column_api_name);
                                if (extIdFieldName != null) {
                                    system.debug('fieldDescribeMap:' + fieldDescribeMap);
                                    Schema.DescribeFieldResult fieldDescribe = fieldDescribeMap.get(header.column_api_name.toLowercase());
                                    system.debug('fieldDescribe:' + fieldDescribe);
                                    if (fieldDescribe != null) {
                                        SObjectType referenceObjectType = ((SObject)Type.forName(fieldDescribe.getReferenceTo()[0].getDescribe().getName()).newInstance()).getSObjectType();
                                        SObject refObject = referenceObjectType.newSObject();
                                        refObject.put(extIdFieldName, line[i]);
                                        genericObject.putSObject(fieldDescribe.getRelationshipName(), refObject);
                                    }
                                }
                            }
                            when 'ExternalId' {
                                genericObject.put(header.column_api_name, line[i]);
                            }
                            when else {
                                genericObject.put(header.column_api_name,line[i]);
                            }
                        }
                        if(!headerDone){
                            headerStr = headerStr != '' ? headerStr +',"' + header.column_name + '"' : '"' + header.column_name + '"';
                        }
                        lineStr = lineStr != '' ? lineStr +',"' + line[i] + '"' : '"' + line[i] + '"';
                        // lineStr += line[i];
                    }
                    if(i == line.size()-1){
                        if(!headerDone) {
                            headerStr += '\n';
                            headerDone = true;
                            csvStr = headerStr;
                        }
                        lineStr += '\n';
                        csvStr = csvStr + lineStr;
                    }
                    i++;
                }
                
                DateTime now = DateTime.now();

                // Format the current date and time to include the date and time in a specific format (e.g., YYYYMMDD_HHMMSS)
                String formattedDateTime = now.format('yyyyMMddHHmmss');

                // Get current time in milliseconds since Unix epoch
                Long currentTimeMillis = System.currentTimeMillis();

                // Combine the formatted date-time with milliseconds to form a unique ID
                //  String uniqueId = formattedDateTime + '_' + currentTimeMillis;
                String uniqueId = formattedDateTime + j;

                

               // if(objectName == 'Product_Mapping__c' || objectName == 'Employee_Customer_Assignment__c' ){
                    if(genericObject.get('Mapping_Id__c') == null){
                        genericObject.put('Mapping_Id__c',uniqueId);
                    }
                    if(selectedUser != null){
                       
                        if(objectName == 'Product_Mapping__c' && genericObject.getSObject('Exectuive__r') == null){
                            genericObject.put('Exectuive__c',selectedUser.Id);
                        }
                        if(objectName == 'Employee_Customer_Assignment__c' && genericObject.getSObject('Executive__r') == null){
                            genericObject.put('Executive__c',selectedUser.Id);
                        }
                    }
               // }
                j++;

                if(objectName == 'PJP_Item__c'){
                   // system.debug(selectedUser);
                    if(selectedUser != null){ 
                        if(selectedUser.Profile.Name == 'DSM' || selectedUser.Profile.Name == 'SSA'){
                            system.debug('Assigned_Beat__c: '+genericObject.get('Assigned_Beat__c'));
                            if(genericObject.getSObject('Assigned_Beat__r') != null){
                                genericObject.putSObject('Beat__r',genericObject.getSObject('Assigned_Beat__r'));
                                genericObject.put('Status__c', 'Approved');
                            }
                        }
                        else{
                            genericObject.put('Status__c', 'Not Submitted');
                        }
                    }
                    else{
                        if(genericObject.getSObject('Assigned_Beat__r') != null){
                            genericObject.putSObject('Beat__r',genericObject.getSObject('Assigned_Beat__r'));
                            genericObject.put('Status__c', 'Approved');
                        }
                    }
                }
                
                //genericObject.put('Data_Upload__c',TRUE);
                recordsToInsert.add(genericObject);
            }
            system.debug('recordsToInsert:' + recordsToInsert);
            BatchInsert recBatch = new BatchInsert(recordsToInsert, Schema.getGlobalDescribe().get(csvData.headers[0].object_name).getDescribe().fields.getMap().get(mapObject.getExternalIdName()), objectName, csvStr);
            Id batchApexCommId = Database.executeBatch(recBatch);
            // upsert recordsToInsert;
            return true;
        }catch(exception e){
            system.debug('Error:' + e.getMessage());
            //throw new AuraHandledException(e.getMessage());
            ExceptionHandler.addLog(e, String.valueOf(csvData), 'CSVCreator');
            return false;
        }
    }

    @AuraEnabled
    public static List<String> getCSVHeader(String objectName, User selectedUser){

      CSVFieldMapping fieldMapping = new CSVFieldMapping(objectName);
        system.debug('fieldMapping:' + fieldMapping.fieldMap.keySet());

        List<String> csvString = new List<String>(fieldMapping.fieldMap.keySet());

        if(objectName == 'Product_Mapping__c' || objectName == 'Employee_Customer_Assignment__c' ){
            if(selectedUser != null){
                String userRow = '\n"' + selectedUser.User_Id__c + '"';

                // Append the new data row to the csvString
                csvString.add(userRow);  // Add the row as a new element in the list
                    
            }
            
        }

        

        return csvString;
    }
   
}