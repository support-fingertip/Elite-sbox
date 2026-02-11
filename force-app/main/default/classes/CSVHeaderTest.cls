@isTest
public class CSVHeaderTest {

    @isTest
    static void testConstructors() {
        // Test default constructor
        CSVHeader header1 = new CSVHeader();
        header1.column_name = 'Test Column';
        header1.column_api_name = 'Test_Column__c';
        header1.object_name = 'TestObject__c';
        header1.column_type = 'String';

        // Assert values
        System.assertEquals('Test Column', header1.column_name);
        System.assertEquals('Test_Column__c', header1.column_api_name);
        System.assertEquals('TestObject__c', header1.object_name);
        System.assertEquals('String', header1.column_type);

        // Test constructor with column name, api name, object name
        CSVHeader header2 = new CSVHeader('Email', 'Email__c', 'Contact');
        System.assertEquals('Email', header2.column_name);
        System.assertEquals('Email__c', header2.column_api_name);
        System.assertEquals('Contact', header2.object_name);
        System.assertEquals(null, header2.column_type);
        
        CSVHeader header3 = new CSVHeader('Test Column', 'Test_Column__c', 'TestObject__c',CSVHeader.toDataType('STRING'));
        

        
    }

    @isTest
    static void testToDataType() {
        // Valid input test
        DataType result1 = CSVHeader.toDataType('String');
       

        // Invalid input test (should return null)
        DataType result2 = CSVHeader.toDataType('InvalidType');
        

        // Null input test
        DataType result3 = CSVHeader.toDataType(null);
        

        // Additional valid input test (e.g., INTEGER)
        DataType result4 = CSVHeader.toDataType('Integer');
       
    }
}