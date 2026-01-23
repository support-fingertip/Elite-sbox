@isTest
public class CSVFieldMappingTest {

    @isTest
    static void testJunctionBeatMapping() {
        CSVFieldMapping mapping = new CSVFieldMapping('Junction_Beat__c');
        
    }

    @isTest
    static void testPJPItemMapping() {
        CSVFieldMapping mapping = new CSVFieldMapping('PJP_Item__c');
        
    }

    @isTest
    static void testEmployeeCustomerAssignmentMapping() {
        CSVFieldMapping mapping = new CSVFieldMapping('Employee_Customer_Assignment__c');
        
   
    }

    @isTest
    static void testProductMapping() {
        CSVFieldMapping mapping = new CSVFieldMapping('Product_Mapping__c');


    }

    @isTest
    static void testDefaultValues() {
        CSVFieldMapping mapping = new CSVFieldMapping('Non_Existing_Object');


    }
}