/*
* created by Roopesh
* purpose : Order, Account integration with Azure   
* calling from  PushTologistics cmp,  AccountTriggerHandler
*/
global class PostHandler {
    @AuraEnabled
    global static boolean sendOrder( string recId){
        order__c ord=[select id,ERP_Check__c,Status__c,Account__r.Customer_Type__c from order__c where id=:recId ];
        if(ord.ERP_Check__c!=true && ord.Account__r.Customer_Type__c == 'Primary Customer'){
            
            ord.Push_to_Logistics__c = 'Yes';
            ord.Status__c = 'Push to Logistics';
            ord.ERP_Check__c=true;
            update ord;
            postHandler.orderPost(ord);
            
            return ord.ERP_Check__c;
        }
        return true;
    }
    
    global static void orderPost( Order__c ordds){
        ordds.ERP_Check__c=false;
        update ordds;
        
        list<string>odId= new list<string>();
        list< map<string,string>>hd=new list< map<string,string>>();
        Order__c ordd = [SELECT Id,Name,Order_Type1__c,Account_Code__c,Customer_SAP_Code__c,Expected_Delivery_Date__c,Delivery_Plant__c,Sales_Organization__c,Division__c,
                         Sales_Channel__c,PO_DATE__c,Order_Date__c,Distribution_Channel__c,Owner_Name__c,Executive_Employee_Code__c,Grand_Total__c,Status__c,DISTRICT__c,createddate,
                         (select id,Name,SKU_Name__c,NET_WEIGHT__c,Tax_Percent__c,Tax__c,Quantity__c,UOM__c,Non_Taxable_Order_Value__c,Tax_Amount__c,Total_Amount__c from  Order_Items__r)
                         FROM Order__c WHERE Id=:ordds.id];
        system.debug('ordd>>'+ordd);   
        
        OrderWrapper ordWrap = new OrderWrapper();
        ordWrap.OrderId=ordd.Name;
        ordWrap.OrderType= ordd.Order_Type1__c!=null?ordd.Order_Type1__c:'';
        ordWrap.CustomerSAPCode= ordd.Customer_SAP_Code__c!=null?ordd.Customer_SAP_Code__c:'';
        ordWrap.CustomerCode= ordd.Account_Code__c!=null?ordd.Account_Code__c:'';
        ordWrap.ExpectedDeliveryDate=ordd.Expected_Delivery_Date__c!=null?string.valueof(ordd.Expected_Delivery_Date__c)+'T00:00:00':'';
        ordWrap.DeliveryPlant= ordd.Delivery_Plant__c!=null?ordd.Delivery_Plant__c:'';
        ordWrap.SalesOrganization= ordd.Sales_Organization__c!=null?ordd.Sales_Organization__c:'';
        ordWrap.Division= ordd.Division__c!=null?ordd.Division__c:'';
        
        Datetime dt = ordd.CreatedDate; 
        String formatted = dt.format('yyyy-MM-dd\'T\'HH:mm:ss');
        
        
        ordWrap.PODate= ordd.PO_DATE__c!=null?string.valueof(ordd.PO_DATE__c)+'T00:00:00':formatted;   //mandatory 
        ordWrap.SalesChannel= ordd.Sales_Channel__c!=null?ordd.Sales_Channel__c:'';
        ordWrap.OrderDate= string.valueof(ordd.Order_Date__c)+'T00:00:00';
        ordWrap.DistributionChannel= ordd.Distribution_Channel__c!=null?ordd.Distribution_Channel__c:'';
        ordWrap.ExecutiveName= ordd.Owner_Name__c; 
        ordWrap.ExecutiveEmployeeCode= ordd.Executive_Employee_Code__c;
        ordWrap.District= ordd.DISTRICT__c!=null?ordd.DISTRICT__c:'';
        ordWrap.GrandTotal= ordd.Grand_Total__c;
        ordWrap.OrderStatus= ordd.Status__c;
        
        list<OrderItemWrapper> oiTemList= new list<OrderItemWrapper>();
        for(Order_Item__c oi:ordd.Order_Items__r){
            OrderItemWrapper oiTem= new OrderItemWrapper();
            oiTem.OrderItemId=oi.name;
            oiTem.ParentOrderId=ordd.name;
            oiTem.SKUCode=oi.SKU_Name__c;
            oiTem.NetWeight=oi.NET_WEIGHT__c;	
            oiTem.TaxPercent= (oi.Tax__c != null) !=null?oi.Tax__c : 0;
            oiTem.Quantity=oi.Quantity__c;
            oiTem.UOM=oi.UOM__c;
            oiTem.NonTaxableOrderValue=oi.Non_Taxable_Order_Value__c;
            oiTem.GSTAmount=oi.Tax_Amount__c;
            oiTem.TaxableOrderValue=oi.Total_Amount__c ;
            oiTemList.ADD(oiTem);
        }
        ordWrap.OrderItems=oiTemList;
        list<OrderWrapper>ordHeader=new list<OrderWrapper>();
        ordHeader.add(ordWrap);
        string orderWrapperJson= JSON.serialize(ordHeader);
        system.debug(orderWrapperJson);
        
        //AzureIntegrationController.sendListEmail(ordd.id);
        AzureIntegrationController.sendOrderMaster(orderWrapperJson,ordd.id);  
        //      
    }
    
    public class OrderWrapper {
        public String OrderId;
        public String OrderType;
        public String CustomerSAPCode;
        public String CustomerCode;
        public String ExpectedDeliveryDate;
        public String DeliveryPlant;
        public String SalesOrganization;
        public String Division;
        public String PODate;
        public String SalesChannel;
        public String OrderDate;
        public String DistributionChannel;
        public String ExecutiveName;
        public String ExecutiveEmployeeCode;
        public String District;
        public decimal GrandTotal;
        public String OrderStatus;
        public List<OrderItemWrapper> OrderItems;
    }
    
    public class OrderItemWrapper {
        public String OrderItemId;
        public String ParentOrderId;
        public String SKUCode;
        public decimal NetWeight;
        public decimal TaxPercent;
        public decimal Quantity;
        public String UOM;
        public decimal NonTaxableOrderValue;
        public decimal GSTAmount;
        public decimal TaxableOrderValue;
        
    }  
    
    global static void accPost( account accts, boolean isCreation){
        AccountTriggerRecursion.skipAzureCall = true;   
        if(!isCreation){
            accts.ERP_Check__c=false;   
        }
        else{
            accts.ERP_Update__c=false;
        }
     
        accts.By_Pass_Validation__c = accts.By_Pass_Validation__c ? false : true;
        
        update accts;
        list<string>odId= new list<string>();
        list< map<string,string>>hd=new list< map<string,string>>();
        account  acc = [SELECT Id,Name,Account_Type__c,Customer_Code__c,SAP_Customer_Code__c,Customer_Group__c,Primary_Customer_Type__c,Customer_Type__c,Customer_Group_Name__c,
                        Primary_Customer_Business_Type__c,Customer_Status__c,Primary_Phone_Number__c,Aadhaar_No__c,GST_Number__c,Email_ID__c,Contact_Person_Name__c,Contact_Person_Phone__c,
                        Secondary_Phone_Number__c, PAN_Number__c,Account_Holder_Name__c,Account_No__c,Bank_Name__c,IFSC_Code__c,Branch_Name__c,Reference_Contact_Name__c,Reference_Contact_Mobile__c,
                        Reference_Email__c,Reference_Address__c,Expected_Turn_over_PA__c,Payment_Type__c,Credit_Limit__c,Company_Name__c, Customer_Activation_Date__c,Customer_Inactivation_Date__c,
                        Land_Mark__c,City_Town__c,Street__c,Pincode__c,GeoLocation__c,Owner_Name__c,OwnerName__c,Security_Cheque_Status__c,Security_Amount__c,State__c,District__c,Door_No__c,Building_Name__c,
                        CreatedDate, (select id,Name,Executive_Name__c,Parent_Depot__c,Child_Depot__c,Sales_Office__c,Order_Type__c,Distribution_Channel__c,Division__c,Payment_Term__c,Inco_Terms__c,
                                      Executive_Employee_Code__c,Primary_Customer_Name__c,Customer_SAP_Code__c,Chanel__c,Territory_Id__c,PDP_Day__c,Territory_Name__c from  Product_Mappings__r)
                        FROM account WHERE Id=:accts.id];
        system.debug('acc>>'+acc);   
        
        
        AccWrapper accWrap = new AccWrapper();
        accWrap.CustomerName=acc.name;
        accWrap.CustomerType=acc.Customer_Type__c!=null?acc.Customer_Type__c:'';  //acc.Account_Type__c!=null?acc.Account_Type__c:'';
        accWrap.CustomerCode=  acc.Customer_Code__c!=null?acc.Customer_Code__c:'';
        accWrap.SAPCustomerCode=acc.SAP_Customer_Code__c!=null?integer.valueof(acc.SAP_Customer_Code__c):0 ;
        accWrap.CustomerGroup=acc.Customer_Group_Name__c!=null?acc.Customer_Group_Name__c:'';
        accWrap.PrimaryCustomerType=acc.Primary_Customer_Type__c!=null?acc.Primary_Customer_Type__c:'';
        accWrap.PrimaryCustomerBusinessType=acc.Primary_Customer_Business_Type__c!=null?acc.Primary_Customer_Business_Type__c:'';
        accWrap.CustomerStatus=acc.Customer_Status__c!=null?acc.Customer_Status__c:'';
        accWrap.PrimaryPhoneNumber=acc.Primary_Phone_Number__c!=null?acc.Primary_Phone_Number__c:'';
        accWrap.AadhaarNo=acc.Aadhaar_No__c!=null?acc.Aadhaar_No__c:'';
        accWrap.GSTNumber=acc.GST_Number__c!=null?acc.GST_Number__c:'';
        accWrap.EmailId=acc.Email_ID__c!=null?acc.Email_ID__c:'';
        accWrap.ContactPersonName=acc.Contact_Person_Name__c!=null?acc.Contact_Person_Name__c:'';
        accWrap.ContactPersonPhone=acc.Contact_Person_Phone__c!=null?acc.Contact_Person_Phone__c:'2121';
        accWrap.AlternatePhoneNumber=acc.Secondary_Phone_Number__c!=null?acc.Secondary_Phone_Number__c:'212';
        accWrap.PANNumber=acc.PAN_Number__c!=null?acc.PAN_Number__c:'';
        accWrap.AccountHolderName=acc.Account_Holder_Name__c!=null?acc.Account_Holder_Name__c:'';			
        accWrap.BankAccountNo=acc.Account_No__c!=null?acc.Account_No__c:'';			 			
        accWrap.BankName=acc.Bank_Name__c!=null?acc.Bank_Name__c:'';		
        accWrap.IFSCCode=acc.IFSC_Code__c!=null?acc.IFSC_Code__c:'';	
        accWrap.BranchName=acc.Branch_Name__c!=null?acc.Branch_Name__c:'';
        accWrap.ReferenceContactName= acc.Reference_Contact_Name__c!=null?acc.Reference_Contact_Name__c:'';	
        accWrap.ReferencePhoneNumber=acc.Reference_Contact_Mobile__c!=null?acc.Reference_Contact_Mobile__c:'111';
        accWrap.ReferenceEmail=acc.Reference_Email__c!=null?acc.Reference_Email__c:'';
        accWrap.ReferenceAddress= acc.Reference_Address__c!=null?acc.Reference_Address__c:'';	
        accWrap.ExpectedTurnoverPA= acc.Expected_Turn_over_PA__c!=null?acc.Expected_Turn_over_PA__c:0;	
        accWrap.PaymentType=acc.Payment_Type__c!=null?acc.Payment_Type__c:'';	
        accWrap.CreditLimit=acc.Credit_Limit__c!=null?acc.Credit_Limit__c:0; 
        accWrap.CompanyName=acc.Company_Name__c!=null?acc.Company_Name__c:'';	
        accWrap.CustomerOwnerName=acc.OwnerName__c;			
        accWrap.SecurityChequeStatus=acc.Security_Cheque_Status__c!=null?acc.Security_Cheque_Status__c:'';	
        accWrap.SecurityAmount=	acc.Security_Amount__c!=null?integer.valueof(acc.Security_Amount__c):0 ; 
        accWrap.State= acc.State__c!=null?acc.State__c:'';	
        accWrap.District=acc.District__c!=null?acc.District__c:'';	
        accWrap.DoorNo= acc.Door_No__c!=null?acc.Door_No__c:'';	
        accWrap.BuildingName= acc.Building_Name__c!=null?acc.Building_Name__c:'';			
        accWrap.LandMark=acc.Land_Mark__c!=null?acc.Land_Mark__c:'';	
        accWrap.CityTown= acc.City_Town__c!=null?acc.City_Town__c:'';	
        accWrap.Street=acc.Street__c!=null?acc.Street__c:'';	
        accWrap.Pincode=acc.Pincode__c!=null?acc.Pincode__c:'' ;
        accWrap.LatitudeLongitude= acc.GeoLocation__c!=null?string.valueof(acc.GeoLocation__c):'';
        
        //New Fields Added by Durga Prasad 15/01/2026
        accWrap.ActivationDate = acc.Customer_Activation_Date__c != null ? acc.Customer_Activation_Date__c.format('yyyy-MM-dd') : null;
        accWrap.CreatedDate = acc.CreatedDate != null  ? acc.CreatedDate.format('yyyy-MM-dd') : null;
        accWrap.InactivationDate = acc.Customer_Inactivation_Date__c != null   ? acc.Customer_Inactivation_Date__c.format('yyyy-MM-dd') : null;
        
        
        system.debug('accWrap>>'+accWrap);      
        list<AccItemWrapper> accItemList= new list<AccItemWrapper>();
        for(Product_Mapping__c oi:acc.Product_Mappings__r){
            
            AccItemWrapper oiTem= new AccItemWrapper();
            oiTem.ProductMappingId=oi.Name; 
            oiTem.ExecutiveName=oi.Executive_Name__c!=null?oi.Executive_Name__c:'';	
            oiTem.ExecutiveEmployeeCode=oi.Executive_Employee_Code__c!=null?oi.Executive_Employee_Code__c:'';	
            oiTem.CustomerName=oi.Primary_Customer_Name__c!=null?oi.Primary_Customer_Name__c:'';	
            oiTem.SAPCustomerCode=oi.Customer_SAP_Code__c!=null?integer.valueof(oi.Customer_SAP_Code__c):0 ; 
            oiTem.SalesChannel=oi.Chanel__c!=null?oi.Chanel__c:'';	
            oiTem.Territory=oi.Territory_Name__c!=null?oi.Territory_Name__c:'';	
            oiTem.PdpDay=oi.PDP_Day__c!=null?oi.PDP_Day__c:'';	
            oiTem.SalesOrganization=oi.Parent_Depot__c!=null?oi.Parent_Depot__c:'';	
            oiTem.DeliveryPlant=oi.Child_Depot__c!=null?oi.Child_Depot__c:'';	
            oiTem.SalesOffice=oi.Sales_Office__c!=null?oi.Sales_Office__c:'';	
            oiTem.OrderType=oi.Order_Type__c!=null?oi.Order_Type__c:'';	
            oiTem.DistributionChannel=oi.Distribution_Channel__c!=null?oi.Distribution_Channel__c:'';	
            oiTem.Division=oi.Division__c!=null?oi.Division__c:'';	
            oiTem.PaymentTerm=oi.Payment_Term__c!=null?oi.Payment_Term__c:'';			
            oiTem.IncoTerms=oi.Inco_Terms__c!=null?oi.Inco_Terms__c:'';	
            accItemList.add(oiTem);
        }
        system.debug('accItemList>>'+accItemList);     
        
        system.debug('accWrap>>'+accWrap);    
        
        AccWrapperHeader addHeader= new AccWrapperHeader();
        addHeader.Customers= accWrap;
        if(accItemList.size()>0){
            addHeader.CustomerDetails=accItemList;
        }
        system.debug('addHeader>>'+addHeader);    
        
        string accWrapperJson= JSON.serialize(addHeader);
        
        system.debug(accWrapperJson);
        AzureIntegrationController.sendAccountMaster(accWrapperJson,acc.id,isCreation);  
        AccountTriggerRecursion.skipAzureCall = false;
    }
    
    public class AccWrapperHeader {
        public AccWrapper Customers;
        public List<AccItemWrapper> CustomerDetails;
        
    }
    public class AccWrapper {
        public String CustomerName;
        public String CustomerType;
        public String CustomerCode;
        public integer SAPCustomerCode;
        public String CustomerGroup;
        public String PrimaryCustomerType;
        public String PrimaryCustomerBusinessType;
        public String CustomerStatus;
        public String PrimaryPhoneNumber;
        public String AadhaarNo;
        public String GSTNumber;
        public String EmailId;
        public String ContactPersonName;
        public String ContactPersonPhone;
        public String AlternatePhoneNumber;
        public String PANNumber;
        public String AccountHolderName;
        public String BankAccountNo;
        public String BankName;
        public String IFSCCode;
        public String BranchName;
        public String ReferenceContactName;
        public String ReferencePhoneNumber;
        public String ReferenceEmail;
        public String ReferenceAddress;
        public decimal ExpectedTurnoverPA;
        public String PaymentType;
        public decimal CreditLimit;
        public String CompanyName;
        public String CustomerOwnerName;
        public String SecurityChequeStatus;
        public decimal SecurityAmount;
        public String State;
        public String District;
        public String DoorNo;
        public String BuildingName;
        public String LandMark;
        public String CityTown;
        public String Street;
        public String Pincode;
        public String LatitudeLongitude;
        public String ActivationDate;
        public String InactivationDate;
        public String CreatedDate;
    }
    
    public class AccItemWrapper {
        public String ProductMappingId;
        public String ExecutiveName;
        public String ExecutiveEmployeeCode;
        public String CustomerName;
        public Integer SAPCustomerCode;
        public String SalesChannel;
        public String Territory;
        public String PdpDay;
        public String SalesOrganization;
        public String DeliveryPlant;
        public String SalesOffice;
        public String OrderType;
        public String DistributionChannel;
        public String Division;
        public String PaymentTerm;
        public String IncoTerms;
        
    }
    
    
}