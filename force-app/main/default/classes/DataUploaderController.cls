public with sharing class DataUploaderController {
    private static final Set<String> ALLOWED_STANDARD_OBJECTS = new Set<String>{
        'account', 'contact', 'opportunity', 'lead', 'case',
        'order', 'contract', 'product2', 'asset', 'campaign', 'quote'
    };
    private static final Integer MAX_CSV_ROWS = 10000;
    private static final String CSV_DELIMITER = ',';
    private static final String QUOTE_CHAR = '"';

    public class ObjectWrapper implements Comparable {
        @AuraEnabled public String label { get; private set; }
        @AuraEnabled public String apiName { get; private set; }
        
        public ObjectWrapper(String label, String apiName) {
            this.label = label;
            this.apiName = apiName;
        }
        
        public Integer compareTo(Object compareTo) {
            return label.compareTo(((ObjectWrapper)compareTo).label);
        }
    }

    public class FieldWrapper {
        @AuraEnabled public String label { get; private set; }
        @AuraEnabled public String apiName { get; private set; }
        @AuraEnabled public String dataType { get; private set; }
        
        public FieldWrapper(String label, String apiName, String dataType) {
            this.label = label;
            this.apiName = apiName;
            this.dataType = dataType;
        }
    }

    public class FailedRecordWrapper {
        @AuraEnabled public Integer rowIndex { get; private set; }
        @AuraEnabled public Map<String, String> rowData { get; private set; }
        @AuraEnabled public List<String> errorMessages { get; private set; }
        @AuraEnabled public String status { get; private set; }
        
        public FailedRecordWrapper(Integer rowIndex, Map<String, String> rowData, List<String> errorMessages) {
            this.rowIndex = rowIndex;
            this.rowData = rowData;
            this.errorMessages = errorMessages;
            this.status = 'failed';
        }
    }

    public class SuccessfulRecordWrapper {
        @AuraEnabled public Integer rowIndex { get; private set; }
        @AuraEnabled public Map<String, String> rowData { get; private set; }
        @AuraEnabled public String status { get; private set; }
        
        public SuccessfulRecordWrapper(Integer rowIndex, Map<String, String> rowData) {
            this.rowIndex = rowIndex;
            this.rowData = rowData;
            this.status = 'success';
        }
    }

    public class DataUploaderException extends Exception {}

    @AuraEnabled(cacheable=true)
    public static List<ObjectWrapper> getObjects() {
        List<ObjectWrapper> objects = new List<ObjectWrapper>();
        
        for (Schema.SObjectType objType : Schema.getGlobalDescribe().values()) {
            Schema.DescribeSObjectResult describe = objType.getDescribe();
            String objName = describe.getName().toLowerCase();
            
            if (describe.isCreateable() && 
                !describe.isCustomSetting() && 
                (describe.isCustom() || ALLOWED_STANDARD_OBJECTS.contains(objName))) {
                objects.add(new ObjectWrapper(describe.getLabel(), objName));
            }
        }
        
        objects.sort();
        return objects;
    }

    @AuraEnabled(cacheable=true)
    public static List<FieldWrapper> getObjectFields(String objectApiName) {
        if (String.isBlank(objectApiName)) {
            throw new AuraHandledException('Object API name cannot be empty');
        }

        List<FieldWrapper> fields = new List<FieldWrapper>();
        SObjectType objType = Schema.getGlobalDescribe().get(objectApiName);
        
        if (objType == null) {
            throw new AuraHandledException('Invalid object API name: ' + objectApiName);
        }

        for (Schema.SObjectField field : objType.getDescribe().fields.getMap().values()) {
            Schema.DescribeFieldResult fieldDesc = field.getDescribe();
            if (fieldDesc.isCreateable()) {
                fields.add(new FieldWrapper(
                    fieldDesc.getLabel(),
                    fieldDesc.getName(),
                    String.valueOf(fieldDesc.getType())
                ));
            }
        }
        
        return fields;
    }

    @AuraEnabled
    public static String fetchCSVContent(String contentVersionId) {
        if (String.isBlank(contentVersionId)) {
            throw new AuraHandledException('Content Version ID cannot be empty');
        }

        try {
            ContentVersion cv = [
                SELECT VersionData 
                FROM ContentVersion 
                WHERE Id = :contentVersionId 
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            return cv.VersionData.toString();
        } catch (Exception e) {
            throw new AuraHandledException('Failed to retrieve file: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static Map<String, Object> uploadCSVData(
        String objectApiName, 
        String csvContent, 
        Map<String, String> fieldMapping
    ) {
        Map<String, Object> result = initializeResult();
        
        try {
            validateInputs(objectApiName, csvContent, fieldMapping);
            List<String> lines = csvContent.split('\n');
            
            if (lines.size() > MAX_CSV_ROWS) {
                throw new DataUploaderException('CSV exceeds maximum row limit of ' + MAX_CSV_ROWS);
            }

            List<String> headers = parseCSVLine(lines[0]);
            SObjectType sObjectType = Schema.getGlobalDescribe().get(objectApiName);
            Map<String, Schema.SObjectField> fieldMap = sObjectType.getDescribe().fields.getMap();
            List<SObject> recordsToInsert = new List<SObject>();
            List<Map<String, String>> rowDataList = new List<Map<String, String>>();
            
            for (Integer i = 1; i < lines.size(); i++) {
                if (String.isBlank(lines[i])) continue;
                
                Map<String, String> rowData = new Map<String, String>();
                processCSVRow(
                    lines[i], 
                    headers, 
                    fieldMapping, 
                    sObjectType, 
                    fieldMap, 
                    recordsToInsert, 
                    result, 
                    i,
                    rowData
                );
                rowDataList.add(rowData);
            }
            
            if (!recordsToInsert.isEmpty()) {
                processInsertResults(Database.insert(recordsToInsert, false), result, rowDataList, headers);
            }
            
            result.put('success', ((Integer)result.get('errorCount')) == 0);
            
        } catch (Exception e) {
            handleException(e, result);
        }
        
        return result;
    }

    private static Map<String, Object> initializeResult() {
        return new Map<String, Object>{
            'success' => false,
            'successCount' => 0,
            'errorCount' => 0,
            'errors' => new List<String>(),
            'failedRecords' => new List<FailedRecordWrapper>(),
            'successfulRecords' => new List<SuccessfulRecordWrapper>()
        };
    }

    private static void validateInputs(
        String objectApiName, 
        String csvContent, 
        Map<String, String> fieldMapping
    ) {
        if (String.isBlank(objectApiName)) {
            throw new DataUploaderException('Object API name cannot be empty');
        }
        if (String.isBlank(csvContent)) {
            throw new DataUploaderException('CSV content cannot be empty');
        }
        if (fieldMapping == null || fieldMapping.isEmpty()) {
            throw new DataUploaderException('Field mapping cannot be empty');
        }
        
        if (Schema.getGlobalDescribe().get(objectApiName) == null) {
            throw new DataUploaderException('Invalid object API name: ' + objectApiName);
        }
    }

    private static List<String> parseCSVLine(String line) {
        List<String> values = new List<String>();
        Boolean inQuotes = false;
        String currentValue = '';
        
        for (Integer i = 0; i < line.length(); i++) {
            String c = line.substring(i, i + 1);
            
            if (c == QUOTE_CHAR) {
                inQuotes = !inQuotes;
            } else if (c == CSV_DELIMITER && !inQuotes) {
                values.add(cleanValue(currentValue));
                currentValue = '';
            } else {
                currentValue += c;
            }
        }
        
        values.add(cleanValue(currentValue));
        return values;
    }

    private static void processCSVRow(
        String line,
        List<String> headers,
        Map<String, String> fieldMapping,
        SObjectType sObjectType,
        Map<String, Schema.SObjectField> fieldMap,
        List<SObject> recordsToInsert,
        Map<String, Object> result,
        Integer rowIndex,
        Map<String, String> rowData
    ) {
        List<String> values = parseCSVLine(line);
        SObject record = sObjectType.newSObject();
        
        for (Integer i = 0; i < headers.size() && i < values.size(); i++) {
            String header = headers[i];
            String value = values[i];
            rowData.put(header, value);
            
            if (!fieldMapping.containsKey(header)) continue;
            
            String fieldName = fieldMapping.get(header);
            
            if (String.isNotBlank(value) && fieldMap.containsKey(fieldName)) {
                try {
                    Schema.DisplayType fieldType = fieldMap.get(fieldName).getDescribe().getType();
                    record.put(fieldName, convertToFieldType(value, fieldType));
                } catch (Exception e) {
                    addError(result, 'Row ' + rowIndex + ': Error setting ' + fieldName + ' - ' + e.getMessage());
                }
            }
        }
        
        recordsToInsert.add(record);
    }

    private static void processInsertResults(
        List<Database.SaveResult> saveResults, 
        Map<String, Object> result,
        List<Map<String, String>> rowDataList,
        List<String> headers
    ) {
        Integer recordIndex = 0;
        for (Database.SaveResult sr : saveResults) {
            if (sr.isSuccess()) {
                result.put('successCount', (Integer)result.get('successCount') + 1);
                ((List<SuccessfulRecordWrapper>)result.get('successfulRecords')).add(
                    new SuccessfulRecordWrapper(
                        recordIndex + 1,
                        rowDataList[recordIndex]
                    )
                );
            } else {
                List<String> errorMessages = new List<String>();
                for (Database.Error err : sr.getErrors()) {
                    errorMessages.add(err.getMessage());
                    addError(result, 'Row ' + (recordIndex + 1) + ': ' + err.getMessage());
                }
                
                ((List<FailedRecordWrapper>)result.get('failedRecords')).add(
                    new FailedRecordWrapper(
                        recordIndex + 1,
                        rowDataList[recordIndex],
                        errorMessages
                    )
                );
            }
            recordIndex++;
        }
    }

    private static void addError(Map<String, Object> result, String errorMessage) {
        ((List<String>)result.get('errors')).add(errorMessage);
        result.put('errorCount', (Integer)result.get('errorCount') + 1);
    }

    private static void handleException(Exception e, Map<String, Object> result) {
        addError(result, e.getMessage());
    }

    private static Object convertToFieldType(String value, Schema.DisplayType fieldType) {
        try {
            switch on fieldType {
                when BOOLEAN {
                    return Boolean.valueOf(value);
                }
                when INTEGER {
                    return Integer.valueOf(value);
                }
                when DOUBLE, CURRENCY {
                    return Decimal.valueOf(value);
                }
                when DATE {
                    return Date.valueOf(value);
                }
                when DATETIME {
                    return Datetime.valueOf(value);
                }
                when else {
                    return value;
                }
            }
        } catch (Exception e) {
            throw new DataUploaderException('Invalid value for type ' + fieldType + ': ' + value);
        }
    }

    private static String cleanValue(String value) {
        return String.isBlank(value) ? '' : value.trim().removeStart(QUOTE_CHAR).removeEnd(QUOTE_CHAR);
    }
}