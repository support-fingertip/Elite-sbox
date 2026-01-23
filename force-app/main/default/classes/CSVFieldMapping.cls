/*
 *********************************************************
Apex Class Name    : CSVFieldMapping
    Created Date       : Apr 12, 2024
    @description       : This class is used to map the field names (API Names) to the CSV Headers
@author            : Mayuri Patel
Modification Log:
    Ver   Date         Author                  Modification
    1.0   12-04-2024   Mayuri Patel            Initial Version
     *********************************************************
 */
public class CSVFieldMapping {
    
    public Map<String,String> fieldMap = new Map<String,String>();
    public Map<String,DataType> typeMap = new Map<String,DataType>();
    public Map<String,String> refFieldMap = new Map<String,String>();
    String externalId = '';
    
    //   public enum DataType {Text, Reference, Picklist, DateType, Checkbox, DateTimeType, DecimalType, IntegerType}
    
    public CSVFieldMapping(){}
    
    public CSVFieldMapping(String objectName){
        
        if(objectName == 'Junction_Beat__c'){
            
            fieldMap.put('Mapping ID','Mapping_Id__c');
            typeMap.put('Mapping_Id__c',DataType.ExternalId);
            externalId = 'Mapping_Id__c';
            
            fieldMap.put('Beat ID','Child_beat__c');
            typeMap.put('Child_beat__c',DataType.Reference);
            refFieldMap.put('Child_beat__c','Beat_ID_Text__c');
            
            fieldMap.put('Customer Code','Account__c');
            typeMap.put('Account__c',DataType.Reference);
            refFieldMap.put('Account__c','Customer_Code_Text__c');
            
            fieldMap.put('Sequence Number','Order_Number__c');
            typeMap.put('Order_Number__c',DataType.DecimalType);
            
        }
        else if(objectName == 'Child_beat__c'){
            
            fieldMap.put('Beat ID','Beat_ID_Text__c');
            typeMap.put('Beat_ID_Text__c',DataType.ExternalId);
            externalId = 'Beat_ID_Text__c';
            
            fieldMap.put('Beat Name','Name');
            typeMap.put('Name',DataType.Text);
            
            fieldMap.put('Primary Customer Code','Primary_Customer__c');
            typeMap.put('Primary_Customer__c',DataType.Reference);
            refFieldMap.put('Primary_Customer__c','SAP_Customer_Code__c');
            
            fieldMap.put('Substockiest Customer Code','Sub_Stockist__c');
            typeMap.put('Sub_Stockist__c',DataType.Reference);
            refFieldMap.put('Sub_Stockist__c','Outlet_Id__c');
            
        }
        else if(objectName == 'PJP_Item__c'){
            
            fieldMap.put('Mapping ID','Mapping_Id__c');
            typeMap.put('Mapping_Id__c',DataType.ExternalId);
            externalId = 'Mapping_Id__c';
            
            fieldMap.put('PJP ID','PJP__c');
            typeMap.put('PJP__c',DataType.Reference);
            refFieldMap.put('PJP__c','PJP_Id_Text__c');
            
            fieldMap.put('Beat ID','Assigned_Beat__c');
            typeMap.put('Assigned_Beat__c',DataType.Reference);
            refFieldMap.put('Assigned_Beat__c','Beat_ID_Text__c');
            
            fieldMap.put('Sequence Number','Order_Number__c');
            typeMap.put('Order_Number__c',DataType.DecimalType);
            
            fieldMap.put('Date','Date__c');
            typeMap.put('Date__c',DataType.DateType);
            
        }
        else if(objectName == 'Employee_Customer_Assignment__c'){
            
            
            fieldMap.put('User Id','Executive__c');
            typeMap.put('Executive__c',DataType.Reference);
            refFieldMap.put('Executive__c','User_Id_Text__c');
            
            fieldMap.put('Customer Code','Customer__c');
            typeMap.put('Customer__c',DataType.Reference);
            refFieldMap.put('Customer__c','Customer_Code_Text__c');
            
            
            fieldMap.put('Mapping ID','Mapping_Id__c');
            typeMap.put('Mapping_Id__c',DataType.ExternalId);
            externalId = 'Mapping_Id__c';
            
            
        }
        else if(objectName == 'Product_Mapping__c'){
            
            
            fieldMap.put('User Id','Exectuive__c');
            typeMap.put('Exectuive__c',DataType.Reference);
            refFieldMap.put('Exectuive__c','User_Id_Text__c');
            
            fieldMap.put('Customer Code','Customer__c');
            typeMap.put('Customer__c',DataType.Reference);
            refFieldMap.put('Customer__c','Customer_Code_Text__c');
            
            fieldMap.put('Primary Customer Code','Primary_Customer__c');
            typeMap.put('Primary_Customer__c',DataType.Reference);
            refFieldMap.put('Primary_Customer__c','Customer_Code_Text__c');
            
            fieldMap.put('Substockiest Customer Code','Sub_Stockiest__c');
            typeMap.put('Sub_Stockiest__c',DataType.Reference);
            refFieldMap.put('Sub_Stockiest__c','Customer_Code_Text__c');
            
            
            fieldMap.put('Sales Channel','Chanel__c');
            typeMap.put('Chanel__c',DataType.Picklist);
            
            fieldMap.put('Territory','Area__c');
            typeMap.put('Area__c',DataType.Reference);
            refFieldMap.put('Area__c','Territory_Code_Text__c');
            
            fieldMap.put('PDP Day','PDP_Day__c');
            typeMap.put('PDP_Day__c',DataType.Picklist);
            
            fieldMap.put('Sales Organization','Parent_Depot__c');
            typeMap.put('Parent_Depot__c',DataType.Picklist);
            
            fieldMap.put('Delivery Plant','Child_Depot__c');
            typeMap.put('Child_Depot__c',DataType.Picklist);
            
            fieldMap.put('Sales Office','Sales_Office__c');
            typeMap.put('Sales_Office__c',DataType.Picklist);
            
            fieldMap.put('Order Type','Order_Type__c');
            typeMap.put('Order_Type__c',DataType.Picklist);
            
            fieldMap.put('Distribution Channel','Distribution_Channel__c');
            typeMap.put('Distribution_Channel__c',DataType.Picklist);
            
            fieldMap.put('Division','Division__c');
            typeMap.put('Division__c',DataType.Picklist);
            
            fieldMap.put('Payment Term','Payment_Term__c');
            typeMap.put('Payment_Term__c',DataType.Picklist);
            
            fieldMap.put('Inco Terms','Inco_Terms__c');
            typeMap.put('Inco_Terms__c',DataType.Picklist);
            
            
            fieldMap.put('Mapping ID','Mapping_Id__c');
            typeMap.put('Mapping_Id__c',DataType.ExternalId);
            externalId = 'Mapping_Id__c';
            
            
        }
        
    }
    
    public String getAPIName(String headerName){
        return fieldMap.containsKey(headerName) ? fieldMap.get(headerName) : null;
    }
    
    public DataType getFieldType(String apiName){
        // system.debug(apiName);
        // system.debug(typeMap);
        return typeMap.containsKey(apiName) ? typeMap.get(apiName) : DataType.Text;
    }
    public String getExternalFieldName(String apiName){
        return refFieldMap.containsKey(apiName) ? refFieldMap.get(apiName) : null;
    }
    
    public String getExternalIdName(){
        return externalId;
    }
}