@isTest
public class CSVObjectTest {

    @isTest
    static void testDefaultConstructor() {
        // Test default constructor
        CSVObject csvObj = new CSVObject();
        
        // Set properties manually
        List<CSVHeader> headers = new List<CSVHeader>{
            new CSVHeader('Name', 'Name', 'Contact'),
            new CSVHeader('Email', 'Email__c', 'Contact', CSVHeader.toDataType('STRING'))
        };
        List<List<String>> lines = new List<List<String>>{
            new List<String>{'John Doe', 'john@example.com'},
            new List<String>{'Jane Smith', 'jane@example.com'}
        };
        csvObj.headers = headers;
        csvObj.lines = lines;
        csvObj.line_count = lines.size();

       
    }

    @isTest
    static void testParameterizedConstructor() {
        // Prepare test data
        List<CSVHeader> headers = new List<CSVHeader>{
            new CSVHeader('Phone', 'Phone__c', 'Contact', CSVHeader.toDataType('STRING')),
            new CSVHeader('Amount', 'Amount__c', 'Opportunity', CSVHeader.toDataType('DOUBLE'))
        };
        List<List<String>> lines = new List<List<String>>{
            new List<String>{'123-456-7890', '1000.50'},
            new List<String>{'987-654-3210', '2000.75'}
        };

        // Test parameterized constructor
        CSVObject csvObj = new CSVObject(headers, lines);

       
    }

    @isTest
    static void testEmptyLines() {
        // Test parameterized constructor with empty lines
        List<CSVHeader> headers = new List<CSVHeader>{
            new CSVHeader('Name', 'Name', 'Contact')
        };
        List<List<String>> lines = new List<List<String>>();

        CSVObject csvObj = new CSVObject(headers, lines);

       
    }

    @isTest
    static void testNullValues() {
        // Test default constructor with null values
        CSVObject csvObj = new CSVObject();
        csvObj.headers = null;
        csvObj.lines = null;
        csvObj.line_count = 0;

        // Assert values
        System.assertEquals(null, csvObj.headers, 'Expected headers to be null');
        System.assertEquals(null, csvObj.lines, 'Expected lines to be null');
        System.assertEquals(0, csvObj.line_count, 'Expected line_count to be 0');
    }
}