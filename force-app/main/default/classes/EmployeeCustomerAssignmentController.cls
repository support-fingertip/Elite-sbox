public with sharing class EmployeeCustomerAssignmentController {
    //Primary customer Assignment
    @AuraEnabled
    public static DataBox getAllData(String recordId, String objectName) {
        DataBox db = new DataBox();
        db.isUserDeactivated = false;
        String userId = UserInfo.getUserId();
        
        User currentUser = [ SELECT Id, Name, Profile.Name, ASM_TSM__c, Employee_Code__c, Territory__c, State__c, District__c,
                            Region__c, Profile_Name__c, Area__c, Territory_Name__c, Sales_Channel__c, Working_District__c,
                            Sr_TSE_TSE__c, RSM__c, Heirarchial_Number__c, isAdmin__c, Is_SSA_DSM__c FROM User WHERE Id = :userId LIMIT 1 ];
        db.currentUser = currentUser;
        
        if (String.isBlank(recordId)) return db;
        
    
        
        Boolean isSSADSM = false;
        Id execUserId;
        Id employeeId;
        String salesChannel;
        String territoryName;
        String terriotyId;
        
        if (objectName == 'User') {
            User user = [SELECT Id, Name, Payroll__c, Is_SSA_DSM__c,IsActive,Sales_Channel__c,Territory__c,Territory_Name__c FROM User WHERE Id = :recordId LIMIT 1];
            list<Employee__c> employee = [ SELECT Id, Name, User__c, Is_Active__c, Payroll__c, Is_SSA_DSM__c,User__r.IsActive,Sales_Channel__c
                                          FROM Employee__c WHERE User__c = :user.Id LIMIT 1];
            if(user != null)
            {
                isSSADSM = user.Is_SSA_DSM__c;
                db.selectedUserName = user.Name;
                db.isUserDeactivated = !user.IsActive;
                territoryName = user.Territory_Name__c;
                terriotyId = user.Territory__c;
                employeeId = !employee.isEmpty() ? employee[0].Id :null;//Employee Id
                execUserId = user.Id;
                salesChannel = user.Sales_Channel__c;
            }
            
        } 
        else if (objectName == 'Employee') {
            Employee__c emp = [SELECT Id, Name, User__c, Is_Active__c, Payroll__c, Is_SSA_DSM__c ,User__r.IsActive,Sales_Channel__c,Territory__c,Territory_Name__c
                               FROM Employee__c  WHERE Id = :recordId  LIMIT 1];
            
            if (emp != null) {
                isSSADSM = emp.Is_SSA_DSM__c;
                db.selectedUserName = emp.Name;
                db.isUserDeactivated = String.isNotBlank(emp.User__c) ? !emp.User__r.IsActive : false;
                employeeId = emp.Id;//Employee Id
                execUserId = emp.User__c;
                salesChannel = emp.Sales_Channel__c;
                territoryName = emp.Territory_Name__c;
                terriotyId = emp.Territory__c;
            }
        }
        db.employeeId = employeeId;
        db.selectedUserId = execUserId;
        db.is_SSA_DSM = isSSADSM;
        db.territoryName = territoryName;
        db.terriotyId = terriotyId;
                
       
        db.primaryCustomerAssignment = new List<Employee_Customer_Assignment__c>();
        db.productMappingList = new List<Product_Mapping__c>();
        
        // -----------------------
        // Query 1: Employee_Customer_Assignment__c
        // -----------------------
        List<String> assignmentConditions = new List<String>();
        if (execUserId != null) {
            assignmentConditions.add('Executive__c = :execUserId');
        }
        if (employeeId != null) {
            assignmentConditions.add('Employee__c = :employeeId');
        }
        
        if (!assignmentConditions.isEmpty()) {
            String assignmentQuery =
                'SELECT Id, Name, Executive__c, Executive__r.Name, Customer__c, Customer__r.Name,Customer__r.SAP_Customer_Code__c,Customer__r.Customer_Code__c,' +
                'Customer__r.Primary_Customer_Type__c, Employee__c, Employee__r.Name ' +
                'FROM Employee_Customer_Assignment__c ' +
                'WHERE (' + String.join(assignmentConditions, ' OR ') + ')';
            
            db.primaryCustomerAssignment = Database.query(assignmentQuery);
        }
        
        // -----------------------
        // Query 2: Product_Mapping__c
        // -----------------------
        List<String> productMappingConditions = new List<String>();
        if (execUserId != null) {
            productMappingConditions.add('Exectuive__c = :execUserId'); // Note: 'Exectuive__c' as per your schema
        }
        if (employeeId != null) {
            productMappingConditions.add('Employee__c = :employeeId');
        }
        
        if (!productMappingConditions.isEmpty()) {
            String productQuery =
                'SELECT Id, Name, Customer__c, Customer__r.Name, Customer__r.Primary_Customer_Type__c,Customer__r.SAP_Customer_Code__c,Customer__r.Customer_Code__c, ' +
                'Customer__r.Customer_Type__c, PDP_Name__c, PDP_Day__c, Parent_Depot__c, ' +
                'Executive_Name__c, Exectuive__c, Exectuive__r.Name, Child_Depot__c, Chanel__c, ' +
                'Area_Name__c, Area__c, Area__r.Name, Credit_Terms__c, Credit_Limit__c, Payment_Type__c, ' +
                'Payment_Term__c, Credit_Description__c, Inco_Terms__c, Primary_Customer_Name__c, ' +
                'Primary_Customer__c, Order_Type__c, Distribution_Channel__c, Sales_Office__c, ' +
                'Division__c, Payment_Type_Formula__c, Employee__c, Employee__r.Name ' +
                'FROM Product_Mapping__c ' +
                'WHERE (' + String.join(productMappingConditions, ' OR ') + ') ' +
                'AND Customer__r.Customer_Type__c = \'Primary Customer\' ' +
                'ORDER BY CreatedDate';
            
            db.productMappingList = Database.query(productQuery);
        }

        
        //For Not SSA/DSM Product Mapping Picklist values needed
        if (!isSSADSM) {
            //Fetch Territory Wise Primary Customers for Filter
            db.territoryWiseCustomersMap = getCustomersGroupedByArea();
            db.parentDeportList = GetPicklistValues.extractPicklistValues('Product_Mapping__c','Parent_Depot__c');
            db.salesChannelList = String.isNotBlank(salesChannel) ? salesChannel.split(';') : new List<String>();
            db.orderTypeDependencyList = [SELECT Sales_Channel__c, Payment_Type__c, Division__c, Order_Type__c FROM Order_Type_Dependency__mdt];
            db.areaList = [SELECT Id, Name, Area__c, Region__c, District__c, Sales_Channel__c, ASM__c, RSM__c FROM Area__c];
            db.parentDeportChildDeportMap = newCustomerLwcController.getDependentMap(new Product_Mapping__c(), 'Parent_Depot__c', 'Child_Depot__c');
            db.paymentTermCreditDescriptionMap = newCustomerLwcController.getDependentMap(new Product_Mapping__c(), 'Payment_Term__c', 'Credit_Description__c');
            db.incotermList = GetPicklistValues.extractPicklistValues('Product_Mapping__c','Inco_Terms__c');
            db.paymemtTermList = GetPicklistValues.extractPicklistValues('Product_Mapping__c','Payment_Term__c'); 
            db.orderTypeList = GetPicklistValues.extractPicklistValues('Product_Mapping__c','Order_Type__c'); 
            db.salesOfficeList = GetPicklistValues.extractPicklistValues('Product_Mapping__c','Sales_Office__c'); 
            db.distributonChannelList = GetPicklistValues.extractPicklistValues('Product_Mapping__c','Distribution_Channel__c'); 
            db.divisionList = GetPicklistValues.extractPicklistValues('Product_Mapping__c','Division__c'); 
            db.pdpDayList = GetPicklistValues.extractPicklistValues('Product_Mapping__c','PDP_Day__c'); 
            db.paymenttypeToOrdertypeMap = newCustomerLwcController.getDependentMap(new Account(), 'Payment_Type__c', 'Order_Type__c');
        }
        else
        {
                    
            list<Account> lstAccounts = [select Id,SAP_Customer_Code__c,Payment_Type__c,Name from Account where Customer_Type__c = 'Primary Customer' and
                                         (Customer_Status__c ='Active' OR Customer_Status__c ='Activation Pending' )];
            
            list<CustomerWrapper> lstPrimaryCustomer = new  list<CustomerWrapper>();
            for(Account acc: lstAccounts)
            {
                CustomerWrapper cm = new CustomerWrapper(
                    acc.Id,
                    acc.Name,
                    acc.Payment_Type__c,
                    acc.SAP_Customer_Code__c
                );
                lstPrimaryCustomer.add(cm);
            }
            db.primarycustomerList = lstPrimaryCustomer;
            
        }
        
        
        return db;
    }
	//Get territoryBasedCustomers
    @AuraEnabled(cacheable=true)
    public static Map<Id, List<CustomerWrapper>> getCustomersGroupedByArea() {
        List<Product_Mapping__c> records = [
            SELECT Area__c, Customer__c, Customer__r.Name, Payment_Type_Formula__c, Customer__r.SAP_Customer_Code__c
            FROM Product_Mapping__c
            WHERE Customer__r.Customer_Type__c = 'Primary Customer' and 
            ( Customer__r.Customer_Status__c ='Active' OR Customer__r.Customer_Status__c ='Activation Pending')
            AND Customer__c != null
        ];
        
        // Outer map: Area__c -> (Inner map to ensure unique Customer__c per area)
        Map<Id, Map<Id, CustomerWrapper>> areaToCustomerMap = new Map<Id, Map<Id, CustomerWrapper>>();
        
        for (Product_Mapping__c pm : records) {
            Id areaId = pm.Area__c;
            Id customerId = pm.Customer__c;
            
            if (!areaToCustomerMap.containsKey(areaId)) {
                areaToCustomerMap.put(areaId, new Map<Id, CustomerWrapper>());
            }
            
            // Only add unique customers per area
            Map<Id, CustomerWrapper> customerMap = areaToCustomerMap.get(areaId);
            if (!customerMap.containsKey(customerId)) {
                customerMap.put(customerId, new CustomerWrapper(
                    customerId,
                    pm.Customer__r.Name,
                    pm.Payment_Type_Formula__c,
                    pm.Customer__r.SAP_Customer_Code__c
                ));
            }

        }
        
        // Convert inner maps to lists
        Map<Id, List<CustomerWrapper>> result = new Map<Id, List<CustomerWrapper>>();
        for (Id areaId : areaToCustomerMap.keySet()) {
            result.put(areaId, new List<CustomerWrapper>(areaToCustomerMap.get(areaId).values()));
        }
        
        return result;
    }

    //Insert ProductMappings
    @AuraEnabled
    public static Product_Mapping__c insertProductMaping(Product_Mapping__c productMapping){ 
        system.debug('productMapping'+productMapping);
        upsert productMapping; 
        return [select Id,Name,Customer__c,Customer__r.Primary_Customer_Type__c , Customer__r.Customer_Type__c,PDP_Name__c,PDP_Day__c,
                Parent_Depot__c,Executive_Name__c,Exectuive__c,Child_Depot__c,Chanel__c,Area_Name__c,Area__c,Area__r.Name, 
                Credit_Terms__c, Credit_Limit__c,Payment_Type__c,Exectuive__r.Name,Customer__r.Name,
                Payment_Term__c,Credit_Description__c,Inco_Terms__c,Primary_Customer_Name__c,Primary_Customer__c,
                Order_Type__c,Distribution_Channel__c,Sales_Office__c, Division__c,Employee__c,Employee__r.Name,
                Customer__r.SAP_Customer_Code__c,Customer__r.Customer_Code__c
                from Product_Mapping__c where Id =: productMapping.Id];
        
    }
    
    //Insert Employee_Customer_Assignment__c
    @AuraEnabled
    public static Employee_Customer_Assignment__c insertExecutiveCustomerMapping(Employee_Customer_Assignment__c executiveCustomerMapping){ 
        
        upsert executiveCustomerMapping; 
        return [select Id,Name,Customer__c,Customer__r.Name,Customer_Name__c,Executive__c,Executive__r.Name,Executive_Name__c,
                Customer__r.Primary_Customer_Type__c,Employee__c,Employee__r.Name,Customer__r.SAP_Customer_Code__c,Customer__r.Customer_Code__c
                from Employee_Customer_Assignment__c where Id =: executiveCustomerMapping.Id]; 
    }
    
    //Secoundary Customer assignment
    @AuraEnabled(cacheable=false)
    public static DataBox getSecondaryCustomerAssignment(String recordId, String objectName)
    { 
        system.debug('recordId'+recordId);
        system.debug('objectName'+objectName);
        DataBox db = new DataBox();
        db.isUserDeactivated = false;
        string userId = UserInfo.getUserId();
        user currentUser = [select Id,Name,Profile.Name,ASM_TSM__c,Employee_Code__c,Territory__c,State__c,District__c,
                            Region__c,Profile_Name__c,Area__c,Territory_Name__c,Sales_Channel__c,Working_District__c,
                            Sr_TSE_TSE__c,RSM__c,Heirarchial_Number__c,isAdmin__c,Is_SSA_DSM__c from user where Id =:userId limit 1];
        db.currentUser = currentUser;
        
        Boolean isSSADSM = false;
        Id execUserId;
        Id employeeId;
        if (objectName == 'User') 
        {   
            User user = [SELECT Id, Name, Payroll__c, Is_SSA_DSM__c,IsActive FROM User WHERE Id = :recordId LIMIT 1 ];
            list<Employee__c> employee = [ SELECT Id, Name, User__c, Is_Active__c, Payroll__c, Is_SSA_DSM__c,User__r.IsActive,Sales_Channel__c
                                          FROM Employee__c WHERE User__c = :user.Id LIMIT 1];
            if(user != null)
            {
                isSSADSM = user.Is_SSA_DSM__c;
                db.selectedUserName = user.Name;
                db.isUserDeactivated = !user.IsActive;
                employeeId = !employee.isEmpty() ? employee[0].Id :null;//Employee Id
                execUserId = user.Id;
            }
           
        }
        else if (objectName == 'Employee') 
        {
            Employee__c emp = [SELECT Id, Name, User__c, Is_Active__c, Payroll__c, Is_SSA_DSM__c ,User__r.IsActive,Sales_Channel__c
                               FROM Employee__c  WHERE Id = :recordId  LIMIT 1];
            
            if (emp != null) {
                db.selectedUserId = emp.User__c;
                isSSADSM = emp.Is_SSA_DSM__c;
                db.selectedUserName = emp.Name;
                db.isUserDeactivated = String.isNotBlank(emp.User__c) ? !emp.User__r.IsActive : false;
                employeeId = emp.Id;//Employee Id
                execUserId = emp.User__c;                
            }
        }
        db.is_SSA_DSM = isSSADSM;
        db.employeeId = employeeId;
        db.selectedUserId = execUserId;
        
        
     
        list<Account> primaryCustomers = new list<Account>();
        //Getting the Primary Customers Assigned
        if (isSSADSM) {
            
            List<String> subQueryConditions = new List<String>();
            if (execUserId != null) {
                subQueryConditions.add('Executive__c = :execUserId');
            }
            if (employeeId != null) {
                subQueryConditions.add('Employee__c = :employeeId');
            }
            
            if (!subQueryConditions.isEmpty()) {
                String accountQuery = 'SELECT Id, Name, Area__c, City__c, Customer_Category__c, Region__c, Division__c, ' +
                    'Phone, Customer_Type__c, SAP_Customer_Code__c, Primary_Customer_Business_Type__c, ' +
                    'Primary_Customer_Type__c, Secondary_Customer_Business_Type__c, Secondary_Customer_Type__c, ' +
                    'Customer_Code__c, Primary_Phone_Number__c ' +
                    'FROM Account WHERE Id IN (SELECT Customer__c FROM Employee_Customer_Assignment__c WHERE ' +
                    String.join(subQueryConditions, ' OR ') + ') ' +
                    'AND (Customer_Status__c = \'Active\' OR Customer_Status__c = \'Activation Pending\') ' +
                    'ORDER BY Name ASC';
                
                primaryCustomers = Database.query(accountQuery);
            }
            
        }
        else
        {

            String baseQuery = 'SELECT Id, Name, Area__c, City__c, Customer_Category__c, Region__c, Division__c, ' +
                'Phone, Customer_Type__c, SAP_Customer_Code__c, Primary_Customer_Business_Type__c, ' +
                'Primary_Customer_Type__c, Secondary_Customer_Business_Type__c, Secondary_Customer_Type__c, ' +
                'Customer_Code__c, Primary_Phone_Number__c ' +
                'FROM Account ' +
                'WHERE Id IN (SELECT Customer__c FROM Product_Mapping__c WHERE ';
            
            List<String> conditions = new List<String>();
            if (execUserId != null) {
                conditions.add('Exectuive__c = :execUserId');
            }
            if (employeeId != null) {
                conditions.add('Employee__c = :employeeId');
            }
            
            if (!conditions.isEmpty()) {
                baseQuery += String.join(conditions, ' OR ') + ') ';
                baseQuery += 'AND Customer_Type__c = \'Primary Customer\' ' +
                    'AND (Customer_Status__c = \'Active\' OR Customer_Status__c = \'Activation Pending\') ' +
                    'ORDER BY Name ASC';
                
                primaryCustomers = Database.query(baseQuery);
            }

            
            
            
        }
        db.primaryCustomers = primaryCustomers;
        set<Id> primaryCustomerIds  = new set<Id>();
        for(Account acc : primaryCustomers)
        {
            primaryCustomerIds.add(acc.Id);
        }
        
        
        
        
        /**---------- All Secoudary Customer---------**/
        list<Product_Mapping__c> AllSproductMappings  = [
            SELECT Id, Name, Customer__c,Customer__r.Name,Customer__r.Secondary_Customer_Type__c,Sub_Stockiest__c,Sub_Stockiest__r.Name,
            Customer__r.Secondary_Customer_Business_Type__c,Primary_Customer__c,Exectuive__c,Primary_Customer__r.Name,
            Customer__r.Primary_Phone_Number__c,Employee__c,Customer__r.Customer_Code__c,Customer__r.Outlet_Id__c FROM Product_Mapping__c WHERE
            Customer__r.Customer_Type__c = 'Secondary Customer' And Primary_Customer__c  IN :primaryCustomerIds
            ORDER BY CreatedDate ];
        
        set<Id> assignedSubStockiest = new set<Id>();
        
        Map<String, Product_Mapping__c> customerMappingMap = new Map<String, Product_Mapping__c>();
        
        for (Product_Mapping__c pm : AllSproductMappings) {
            
            String customerId = String.valueOf(pm.Customer__c);
            String primaryId = String.valueOf(pm.Primary_Customer__c);
            String subStockistId = String.valueOf(pm.Sub_Stockiest__c);
            if((pm.Exectuive__c ==  execUserId || pm.Employee__c == employeeId) && pm.Customer__r.Secondary_Customer_Type__c == 'Sub Stockiest')
            {
                assignedSubStockiest.add(pm.Customer__c);
            }
            
            
            String compositeKey = customerId + '-' + primaryId + '-' + subStockistId;
            
            if (!customerMappingMap.containsKey(compositeKey)) {
                customerMappingMap.put(compositeKey, pm);
            } 
            else if (pm.Exectuive__c == execUserId) {
                customerMappingMap.put(compositeKey, pm); // override with selected exec mapping
            }
        }
        
        
        system.debug('customerMappingMap.values()===========>'+customerMappingMap.values());
        system.debug('size===========>'+customerMappingMap.values().size()); 
        list<SCustomers> sCustomerList = new list<SCustomers>();
        for(Product_Mapping__c pm : customerMappingMap.values())
        {
            if((pm.Sub_Stockiest__c != null  && assignedSubStockiest.contains(pm.Sub_Stockiest__c)) || pm.Sub_Stockiest__c == null )
            {
                // Add the composite key
                String customerId = String.valueOf(pm.Customer__c);
                String primaryId = String.valueOf(pm.Primary_Customer__c);
                String subStockistId = String.valueOf(pm.Sub_Stockiest__c);
                
                SCustomers sc = new SCustomers();
                sc.customerName = pm.Customer__r != null ? pm.Customer__r.Name : '';
                sc.customerId = pm.Customer__c;
                sc.customerCode = pm.Customer__r != null ? pm.Customer__r.Customer_Code__c :'';
                sc.outletId = pm.Customer__r != null ? pm.Customer__r.Outlet_Id__c :''; 
                
                sc.customerType = pm.Customer__c != null ? pm.Customer__r.Secondary_Customer_Type__c : '';
                sc.customerBussinessType = pm.Customer__c != null ? pm.Customer__r.Secondary_Customer_Business_Type__c : '';
                sc.primaryCustomerName = pm.Primary_Customer__c != null ? pm.Primary_Customer__r.Name : '';
                sc.primaryCustomerId = pm.Primary_Customer__c;
                sc.phoneNumber = pm.Customer__c != null ? pm.Customer__r.Primary_Phone_Number__c : '';   
                if(execUserId != null && execUserId == pm.Exectuive__c)
                {
                    sc.isSelected = true;
                }
                else if(employeeId != null && pm.Employee__c == employeeId)
                {
                     sc.isSelected = true;
                }
                else
                {
                    sc.isSelected = false;
                }
                sc.productMappingId =  (execUserId == pm.Exectuive__c || pm.Employee__c == employeeId) ? pm.Id : null ;
                sc.isUnderSubStockiest = pm.Sub_Stockiest__c != null ? true : false;
                sc.parentSubStoickistId = pm.Sub_Stockiest__c;
                sc.compositekey = customerId + '-' + primaryId + '-' + subStockistId;
                sc.parentSubstockiestName = pm.Sub_Stockiest__c != null ? pm.Sub_Stockiest__r.Name : '';
                sCustomerList.add(sc);    
            }
        }
        db.sCustomerList = sCustomerList;            
        
        return db;
    }
    @AuraEnabled
    public static void saveProductMappings(List<Product_Mapping__c> mappingList,list<Id> productMappingtoDelete) {
        if (mappingList == null || mappingList.isEmpty()) return;
        
        system.debug('mappingList'+mappingList);
        system.debug('productMappingtoDelete'+productMappingtoDelete);
        list<Product_Mapping__c> deleteProductmapping = [select Id from Product_Mapping__c where Id IN: productMappingtoDelete];
        if(!deleteProductmapping.isEmpty())
        {
            delete deleteProductmapping;
        }
        upsert mappingList;
    }
    
    
    //wrapper class 
    public class DataBox {
        @AuraEnabled public List<Employee_Customer_Assignment__c> primaryCustomerAssignment = new List<Employee_Customer_Assignment__c>();
        @AuraEnabled public List<Account> primaryCustomers = new List<Account>();
        @AuraEnabled public List<Product_Mapping__c> productMappingList;
        @AuraEnabled public boolean isUserDeactivated;
        @AuraEnabled public string selectedUserId;
        @AuraEnabled public string selectedUserName;
        @AuraEnabled public boolean is_SSA_DSM;
        
        @AuraEnabled public List<Map<String, String>> parentDeportList = new List<Map<String, String>> ();
        @AuraEnabled public Map<Id, List<String>> userIdToSalesChannelsMap = new Map<Id, List<String>> ();
        @AuraEnabled public List<Area__c> areaList;
        @AuraEnabled public List<PDP__c> PDPList;
        @AuraEnabled public List<String> salesChannelList = new List<String>();
        @AuraEnabled public Map<String, Map<String, String>> parentDeportChildDeportMap = new  Map<String, Map<String, String>>();
        @AuraEnabled public Map<String, Map<String, String>> paymentTermCreditDescriptionMap = new  Map<String, Map<String, String>>();
        
        @AuraEnabled public List<Map<String, String>> incotermList = new List<Map<String, String>> ();
        @AuraEnabled public List<Map<String, String>> paymemtTermList = new List<Map<String, String>> ();
        @AuraEnabled public List<Map<String, String>> orderTypeList = new List<Map<String, String>> ();
        @AuraEnabled public List<Map<String, String>> salesOfficeList = new List<Map<String, String>> ();
        @AuraEnabled public List<Map<String, String>> distributonChannelList = new List<Map<String, String>> ();
        @AuraEnabled public List<Map<String, String>> divisionList = new List<Map<String, String>> ();
        @AuraEnabled public List<Map<String, String>> pdpDayList = new List<Map<String, String>> ();
        @AuraEnabled public Map<Id, List<Account>> primaryCustomerToSubStockiestMap = new Map<Id, List<Account>> ();
        @AuraEnabled public Map<String, Map<String, String>> paymenttypeToOrdertypeMap = new  Map<String, Map<String, String>>();
        @AuraEnabled public User currentUser;
        @AuraEnabled public list<SCustomers> sCustomerList;
        @AuraEnabled public list<CustomerWrapper> primarycustomerList;
        @AuraEnabled public Map<Id, List<CustomerWrapper>> territoryWiseCustomersMap = new Map<Id, List<CustomerWrapper>>();
        
        //New change
        @AuraEnabled public string employeeId;
        @AuraEnabled public string terriotyId;
        @AuraEnabled public string territoryName;  
        @AuraEnabled public List<Order_Type_Dependency__mdt> orderTypeDependencyList = new List<Order_Type_Dependency__mdt> ();
    }
    public class CustomerWrapper {
        @AuraEnabled public Id customerId;
        @AuraEnabled public String customerName;
        @AuraEnabled public String paymentTypeFormula;
        @AuraEnabled public String sapCode;
        public CustomerWrapper(Id customerId, String customerName, String paymentTypeFormula,String sapCode) {
            this.customerId = customerId;
            this.customerName = customerName;
            this.paymentTypeFormula = paymentTypeFormula;
            this.sapCode = sapCode;
        }
    }
    
    public class SCustomers{
        @AuraEnabled public String productMappingId;
        @AuraEnabled public String customerName;
        @AuraEnabled public String customerId;
        @AuraEnabled public String outletId;
        @AuraEnabled public String customerType;
        @AuraEnabled public String customerBussinessType;
        @AuraEnabled public String customerPhoneNumber;
        @AuraEnabled public String primaryCustomerName;
        @AuraEnabled public String primaryCustomerId;
        @AuraEnabled public String phoneNumber;
        @AuraEnabled public boolean isSelected;
        @AuraEnabled public boolean isUnderSubStockiest;
        @AuraEnabled public String parentSubStoickistId;
        @AuraEnabled public String parentSubstockiestName;
        @AuraEnabled public String compositekey;
        @AuraEnabled public String customerCode;
        
    }
    
}