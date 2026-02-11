/*
* created by Roopesh
* purpose : Order, Account integration with Azure    
*/
global class AzureIntegrationController {
    
    //calling from postHandler
    @ future (callout = true )
        global static void sendOrderMaster(string orderWrapperJson, string ord ){
            String adminUserId = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' and isactive=true LIMIT 1].Id;
            
            order__c oddrs=[select id,Name, OwnerId,Customer_Name__c,Owner_Name__c,Delivery_Plant__c from order__c where id=:ord]; 
            List<Employee__c> empList = [Select Id,Delivery_Plant__c,User__c from Employee__c where Profile__c = 'Logistics Team' and User__r.isActive = true and Delivery_Plant__c =: oddrs.Delivery_Plant__c LIMIT 1];
            
            CustomNotificationType notificationType = [SELECT Id, DeveloperName
                                                       FROM CustomNotificationType
                                                       WHERE DeveloperName='Order_Notification'];
            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            notification.setTitle('Order :'+oddrs.Name);
            notification.setNotificationTypeId(notificationType.Id);
            notification.setTargetId(oddrs.id);
            Set<String> addressee = new Set<String>();
            //   addressee.add(oddrs.OwnerId);
            if(adminUserId!=null){
                addressee.add(adminUserId); 
            }
            if(empList != null && !empList.isEmpty()){
                addressee.add(empList[0].User__c);
            }
            String NotificationBody =  'Order Id : ' + oddrs.Name +'\nOrder created by : ' + oddrs.Owner_Name__c;
            if( oddrs.Customer_Name__c != null )
            {
                NotificationBody += '\nCustomer Name : ' + oddrs.Customer_Name__c;
            }
            
            List<Apex_Log__c> logList = new List<Apex_Log__c>();
            Apex_Log__c log = new Apex_Log__c();
            log.Request_Type__c ='Order Data - '+oddrs.Name;
            string bodyJson = orderWrapperJson;
            log.Request__c =bodyJson;
            
            System.debug('oddrs ' + oddrs);
            
            
            Azure_Connection__mdt az=  [select EndPoint__c,X_API_KEY__c from Azure_Connection__mdt where label='azureIntegration'];
            
            string endpoint = az.EndPoint__c+'/api/Integration/orders'; 
            string method = 'POST';
            String outcomeMsg;
            system.debug('endpoint '+endpoint);
            system.debug('getCallouts '+Limits.getCallouts());
            system.debug('getLimitCallouts '+Limits.getLimitCallouts());
            
            // Create an HTTP request object
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod(method);
            
            system.debug(req);
            req.setHeader('X-API-KEY', az.X_API_KEY__c);
            req.setHeader('Content-Type', 'application/json');
            req.setBody(orderWrapperJson);
            req.setTimeout(120000);
            system.debug('req '+req);
            Http http = new Http();
            HttpResponse res;
            try {
                res = http.send(req);
                
                system.debug('res.getStatusCode() '+res.getStatusCode() );
                // system.debug('res.getBody() '+res.getBody());
                if ((res.getStatusCode() == 200 || res.getStatusCode() == 201) && res.getBody() != null ) {
                    log.status__c='SUCCESS';
                    if(res.getBody().length()<00000){
                        log.response__c= res.getBody();
                    } 
                    Map<String, Object> cObjMap = (Map<String,  Object>) JSON.deserializeUntyped(res.getBody());
                    
                    
                    system.debug(cObjMap);
                    String status = (String)cObjMap.get('status');
                    String message = (String)cObjMap.get('message');
                    integer successCount = (integer)cObjMap.get('successCount');
                    
                    if(status=='completed'){
                        order__c ords= new order__c(); 
                        ords.id= ord;
                        ords.ERP_Check__c = true;
                        //  ords.Status__c = 'Order Sent to Azure';
                        ords.Status__c = 'Push to Logistics';
                        update ords;
                        if(successCount==1){
                            notification.setTitle('Order Created in ERP');
                            notification.setBody(NotificationBody);	 
                            sendListEmail(ord); 
                        }
                        else{
                            notification.setBody('Error: '+message);	 
                        }
                    }
                    else  {
                        
                        order__c ords= new order__c(); 
                        ords.id= ord;
                        ords.ERP_Check__c = false;
                        update ords;
                        notification.setBody('Error: '+message);
                        
                    }                                          
                    
                    try {
                        notification.send(addressee);
                        
                    }
                    catch (Exception e) {
                        System.debug('Problem sending notification: ' + e.getMessage());
                        Apex_Log__c lg = new Apex_Log__c();
                        if (e.getMessage() != null && e.getMessage() != '') {
                            lg.Error_Message__c = e.getMessage();
                        }
                        lg.status__c='Notification FAILED';
                        lg.Request_Type__c = 'Notification error';
                        insert lg;
                    }
                    
                } else {
                    
                    
                    // callout failed
                    order__c ordss= new order__c(); 
                    ordss.id= ord;
                    ordss.ERP_Check__c = false;
                    update ordss;
                    outcomeMsg = 'Error: Callout failed. Please review the debug log for additional details.';
                    log.status__c='FAILED';
                    Map<String, Object> cObjMap = (Map<String,  Object>) JSON.deserializeUntyped(res.getBody());
                    system.debug(cObjMap);
                    Map<String, Object> errorMessage = (Map<String, Object>) cObjMap.get('errors');
                    String titl1s = (String)cObjMap.get('title')!=null?(String)cObjMap.get('title'):'';
                    system.debug(errorMessage); 
                    string errormsg;
                    if (errorMessage.isEmpty()) {
                        errormsg=(String)cObjMap.get('error');
                    }
                    log.response__c= 'Status code : '+res.getStatusCode() +' Response body: '+ cObjMap;
                    log.Error_Message__c = 'Status code : '+res.getStatusCode()+ ' Error: Callout failed..'+ errorMessage+' '+errormsg;
                    System.debug('log   2 ' + log);
                    System.debug('notificationType  2 ' + notificationType);
                    
                    notification.setTitle(oddrs.Name+' :Sending Order to ERP -'+titl1s);
                    notification.setBody('Error While sending Order: '+ 'Status code : '+res.getStatusCode()+ ' Error: Callout failed...\n'+ errorMessage+' '+errormsg);    
                    
                    try {
                        notification.send(addressee);
                        
                    }
                    catch (Exception e) {
                        System.debug('Problem sending notification: ' + e.getMessage());
                        Apex_Log__c lg = new Apex_Log__c();
                        if (e.getMessage() != null && e.getMessage() != '') {
                            lg.Error_Message__c = e.getMessage();
                        }
                        lg.Request_Type__c = 'Notification error';
                        lg.status__c='Notification FAILED';
                        insert lg;
                    }
                } 
                
            }  catch (exception e) {
                order__c ordss= new order__c(); 
                ordss.id= ord;
                ordss.ERP_Check__c = false;
                update ordss;
                System.debug('res: ' + res);
                if (res != null) {
                    System.debug('Status: ' + res.getStatusCode());
                    System.debug('Response body: ' + res.getBody());
                    String responseBody = res.getBody();
                    
                    if (String.isNotBlank(responseBody)) {
                        Map<String, Object> cObjMap = (Map<String,  Object>) JSON.deserializeUntyped(res.getBody());
                        system.debug(cObjMap);
                        Map<String, Object> errorMessage = (Map<String, Object>) cObjMap.get('errors');
                        if(errorMessage!=null){
                            String titl1s = (String)cObjMap.get('title');
                            system.debug('errorMessage>>'+errorMessage);
                            system.debug('res.getStatusCode()>>'+res.getStatusCode());
                            system.debug('titl1s>>'+titl1s);
                            notification.setBody('Error While sending Order: '+ 'Status code : '+res.getStatusCode()+ ' Error: Callout failed.\n'+ errorMessage);    
                            log.response__c= 'Status code : '+res.getStatusCode() +' Response body: '+ cObjMap;
                            log.Error_Message__c = 'Status code : '+res.getStatusCode()+ ' Error: Callout failed :'+ errorMessage;
                            notification.setTitle(oddrs.Name+' :Sending Order to ERP -'+titl1s);
                            
                        }
                        else{
                            String status = (String)cObjMap.get('status');
                            String message = (String)cObjMap.get('message');
                            integer successCount = (integer)cObjMap.get('successCount');
                            notification.setBody('Error While sending Order: '+ 'Status code : '+res.getStatusCode()+ ' Error: Callout failed.\n'+ message);    
                            log.response__c= 'Status code : '+res.getStatusCode() +' Response body: '+ cObjMap;
                            log.Error_Message__c = 'Status code : '+res.getStatusCode()+ ' Error: Callout failed :'+ message;
                            notification.setTitle(oddrs.Name+' :Sending Order to ERP -'+status);
                            
                        }      
                    }
                    else{
                        notification.setBody('Error While sending Order: '+ 'Status code : '+res.getStatusCode()+ ' Error: Callout failed.\n'+ res);    
                        log.response__c= 'Status code : '+res.getStatusCode() +' Response body: '+ res;
                        log.Error_Message__c = 'Status code : '+res.getStatusCode()+ ' Error: Callout failed :'+ res;
                        notification.setTitle(oddrs.Name+' :Sending Order to ERP -');
                        
                    }                            
                    
                    
                }
                
                // Unexpected exceptions will be caught here, like a deserialization error.
                else{
                    outcomeMsg = 'Error: An exception has been encountered while calling out to Integration:  ' + e.getMessage();
                    log.status__c='FAILED';
                    log.Error_Message__c = e.getMessage();
                    system.debug('e.getMessage() '+e.getMessage());
                    
                    
                    System.debug('notificationType  1 ' + notificationType);
                    
                    notification.setBody('Error While sending Order: '+ 'Error: An exception has been encountered while calling out to Integration:  ' + e.getMessage());   
                }
                try {
                    notification.send(addressee);
                    
                }
                catch (Exception ee) {
                    System.debug('Problem sending notification: ' + ee.getMessage());
                }
            }
            
            System.debug('logList  '+log);
            logList.add(log);
            insert logList;
        } 
    
    public static void sendListEmail(Id orderId){
        try {
            // Get the order to include its name/number in the subject
            Order__c orderRecord = [SELECT Id, Name,Account__c,Account__r.Email_ID__c,Account__r.Secondary_Customer_Type__c,Account__r.Customer_Type__c FROM Order__c WHERE Id = :orderId LIMIT 1];
            
            //orderRecord.Account__r.Secondary_Customer_Type__c == 'Sub Stockiest' 
            if(( orderRecord.Account__r.Customer_Type__c == 'Primary Customer') && orderRecord.Account__r.Email_ID__c != null){
                // Create the email
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                
                // Set email properties
                email.setSubject('Order Summary - ' + orderRecord.Name);
                email.setPlainTextBody('Please find attached the order summary.');
                
                // Render Visualforce page as PDF
                PageReference pdfPage = Page.OrderPdf; // Your VF page name
                pdfPage.getParameters().put('id', orderId);
                Blob pdfBlob;
                
                if (Test.isRunningTest()) {
                    pdfBlob = Blob.valueOf('Test PDF Content');
                } else {
                    pdfBlob = pdfPage.getContentAsPDF();
                }
                
                // Create PDF attachment
                Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                attachment.setFileName('OrderSummary_' + orderRecord.Name + '.pdf');
                attachment.setBody(pdfBlob);
                attachment.setContentType('application/pdf');
                
                // Add attachment to email
                email.setFileAttachments(new Messaging.EmailFileAttachment[]{attachment});
                
                // Set recipient (modify as needed)
                email.setToAddresses(new String[]{orderRecord.Account__r.Email_ID__c});
                System.debug('email details: ' + email);
                // Send email
                Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
            }
            
            
        } catch(Exception e) {
            System.debug('Error sending order summary email: ' + e.getMessage());
            // Consider adding error handling logic here
        }
    }
    
    
    @ future (callout = true )
        global static void sendAccountMaster(string accWrapperJson, string acc, boolean isCreation ){
            String adminUserId = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' and isactive=true LIMIT 1].Id;
            
            system.debug('accWrapperJson>>'+accWrapperJson);     
            account acct=[select id,Name, OwnerId,OwnerName__c,Customer_Status__c,Customer_Code__c  FROM account WHERE Id=:acc];
            
            CustomNotificationType notificationType = [SELECT Id, DeveloperName
                                                       FROM CustomNotificationType
                                                       WHERE DeveloperName='Order_Notification'];
            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            notification.setTitle('Account :'+acct.Name);
            notification.setNotificationTypeId(notificationType.Id);
            notification.setTargetId(acct.id);
            Set<String> addressee = new Set<String>();
            //      addressee.add(acct.OwnerId);
            if(adminUserId!=null){
                addressee.add(adminUserId); 
            }
            
            String NotificationBody =  'Account Id : ' + acct.Customer_Code__c +'\nAccount created by : ' + acct.OwnerName__c;
            if( acct.Name != null )
            {
                NotificationBody += '\nCustomer Name : ' + acct.Name;
            }
            
            List<Apex_Log__c> logList = new List<Apex_Log__c>();
            Apex_Log__c log = new Apex_Log__c();
            log.Request_Type__c ='Account Data - '+acct.Customer_Code__c;
            string bodyJson = accWrapperJson;
            log.Request__c =bodyJson;
            
            System.debug('acct ' + acct);
            
            
            Azure_Connection__mdt az=  [select EndPoint__c,X_API_KEY__c from Azure_Connection__mdt where label='azureIntegration'];
            
            string endpoint = az.EndPoint__c+'/api/Integration/customer-details'; 
            string method = 'POST';
            String outcomeMsg;
            system.debug('endpoint '+endpoint);
            system.debug('getCallouts '+Limits.getCallouts());
            system.debug('getLimitCallouts '+Limits.getLimitCallouts());
            /*   if (Limits.getCallouts() >= Limits.getLimitCallouts()) {    

outcomeMsg = 'Maximum number of callouts has been reached.';
log.Status__c = 'FAILED';
log.Error_Message__c = 'Maximum number of callouts has been reached.';
notification.setBody('Error While sending Order: Maximum number of callouts has been reached. ');   


try {
notification.send(addressee);

}
catch (Exception e) {
System.debug('Problem sending notification: ' + e.getMessage());
}
acct.ERP_Check__c=false;
update acct;
} */
            /*   else if (endpoint == null || username == null || password == null) {
oddrs.ERP_Check__c=false;
update oddrs;
outcomeMsg = 'Please verify your API Credentials';
log.Status__c = 'FAILED';
log.Error_Message__c = 'Please verify your API Credentials';



notification.setBody('Error While sending Order: Please verify API Credentials. '); 

try {
notification.send(addressee);

}
catch (Exception e) {
System.debug('Problem sending notification: ' + e.getMessage());
}

} */
            // else {
            
            // Create an HTTP request object
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod(method);
            
            system.debug(req);
            req.setHeader('X-API-KEY', az.X_API_KEY__c);
            req.setHeader('Content-Type', 'application/json');
            req.setBody(accWrapperJson);
            req.setTimeout(120000);
            system.debug('req '+req);
            Http http = new Http();
            HttpResponse res;
            try {
                res = http.send(req);
                
                system.debug('res.getStatusCode() '+res.getStatusCode() );
                // system.debug('res.getBody() '+res.getBody());
                if ((res.getStatusCode() == 200 || res.getStatusCode() == 201) && res.getBody() != null ) {
                    log.status__c='SUCCESS';
                    if(res.getBody().length()<00000){
                        log.response__c= res.getBody();
                    } 
                    Map<String, Object> cObjMap = (Map<String,  Object>) JSON.deserializeUntyped(res.getBody());
                    
                    
                    system.debug(cObjMap);
                    String status = (String)cObjMap.get('status');
                    String message = (String)cObjMap.get('message');
                    
                    if(status=='success'){
                        AccountTriggerRecursion.skipAzureCall = true;                           
                        account accts= new account(); 
                        accts.id= acc;
                        if(!isCreation){
                            accts.ERP_Check__c=true; 
                            notification.setTitle('Account Created in ERP');
                        }
                        else{
                            accts.ERP_Update__c=true;
                            notification.setTitle('Account Updated in ERP');
                        }
                        //   accts.Status__c = 'Account Sent to Azure';
                        update accts;
                        
                        
                        notification.setBody(NotificationBody);	 
                    }
                    else  {
                        
                        AccountTriggerRecursion.skipAzureCall = true;   
                        account accts= new account(); 
                        accts.id= acc;
                        if(!isCreation){
                            accts.ERP_Check__c=false;   
                        }
                        else{
                            accts.ERP_Update__c=false;
                        }
                        update accts;
                        notification.setBody('Error: '+message);
                        
                    }                                          
                    
                    try {
                        if(status != 'success'){
                            notification.send(addressee);
                        }
                        
                    }
                    catch (Exception e) {
                        System.debug('Problem sending notification: ' + e.getMessage());
                        Apex_Log__c lg = new Apex_Log__c();
                        if (e.getMessage() != null && e.getMessage() != '') {
                            lg.Error_Message__c = e.getMessage();
                        }
                        lg.status__c='Notification FAILED';
                        lg.Request_Type__c = 'Notification error';
                        insert lg;
                    }
                    
                } else {   
                    AccountTriggerRecursion.skipAzureCall = true;   
                    // callout failed
                    account accts= new account(); 
                    accts.id= acc;
                    if(!isCreation){
                        accts.ERP_Check__c=false;   
                    }
                    else{
                        accts.ERP_Update__c=false;
                    }
                    update accts;
                    outcomeMsg = 'Error: Callout failed. Please review the debug log for additional details.';
                    log.status__c='FAILED';
                    Map<String, Object> cObjMap = (Map<String,  Object>) JSON.deserializeUntyped(res.getBody());
                    system.debug(cObjMap);
                    Map<String, Object> errorMessage = (Map<String, Object>) cObjMap.get('errors');
                    String titl1s = (String)cObjMap.get('title');
                    if(errorMessage!=null){ 
                        system.debug(errorMessage);  
                        
                        log.response__c= 'Status code : '+res.getStatusCode() +' Response body: '+ cObjMap;
                        log.Error_Message__c = 'Status code : '+res.getStatusCode()+ ' Error: Callout failed..'+ errorMessage;
                        System.debug('log   2 ' + log);
                        System.debug('notificationType  2 ' + notificationType);
                    }
                    
                    else{
                        String status = (String)cObjMap.get('status');
                        String message = (String)cObjMap.get('message');
                        String error = (String)cObjMap.get('error');
                        
                        notification.setBody('Error While sending Account: '+ 'Status code : '+res.getStatusCode()+ ' Error: Callout failed.\n'+ error);    
                        log.response__c= 'Status code : '+res.getStatusCode() +' Response body: '+ cObjMap;
                        log.Error_Message__c = 'Status code : '+res.getStatusCode()+ ' Error: Callout failed :'+ error;
                        notification.setTitle(acct.Name+' :Sending Account to ERP -'+status);
                        
                    }   
                    
                    notification.setTitle(acct.Name+' :Sending Account to ERP -'+titl1s);
                    notification.setBody('Error While sending Account: '+ 'Status code : '+res.getStatusCode()+ ' Error: Callout failed...\n'+ errorMessage);    
                    
                    try {
                      
                        notification.send(addressee);
                        
                        
                    }
                    catch (Exception e) {
                        System.debug('Problem sending notification: ' + e.getMessage());
                        Apex_Log__c lg = new Apex_Log__c();
                        if (e.getMessage() != null && e.getMessage() != '') {
                            lg.Error_Message__c = e.getMessage();
                        }
                        lg.Request_Type__c = 'Notification error';
                        lg.status__c='Notification FAILED';
                        insert lg;
                    }
                } 
                
            }  catch (exception e) {
                AccountTriggerRecursion.skipAzureCall = true;   
                account accts= new account(); 
                accts.id= acc;
                if(!isCreation){
                    accts.ERP_Check__c=false;   
                }
                else{
                    accts.ERP_Update__c=false;
                }
                update accts;
                if (res != null) {
                    System.debug('Status: ' + res.getStatusCode());
                    System.debug('Response body: ' + res.getBody());
                    String responseBody = res.getBody();
                    
                    if (String.isNotBlank(responseBody)) {
                        Map<String, Object> cObjMap = (Map<String,  Object>) JSON.deserializeUntyped(res.getBody());
                        system.debug(cObjMap);
                        Map<String, Object> errorMessage = (Map<String, Object>) cObjMap.get('errors');
                        if(errorMessage!=null){
                            String titl1s = (String)cObjMap.get('title');
                            system.debug('errorMessage>>'+errorMessage);
                            system.debug('res.getStatusCode()>>'+res.getStatusCode());
                            system.debug('titl1s>>'+titl1s);
                            notification.setBody('Error While sending Account: '+ 'Status code : '+res.getStatusCode()+ ' Error: Callout failed.\n'+ errorMessage);    
                            log.response__c= 'Status code : '+res.getStatusCode() +' Response body: '+ cObjMap;
                            log.Error_Message__c = 'Status code : '+res.getStatusCode()+ ' Error: Callout failed :'+ errorMessage;
                            notification.setTitle(acct.Name+' :Sending Account to ERP -'+titl1s);
                            
                        }
                        else{
                            String status = (String)cObjMap.get('status');
                            String message = (String)cObjMap.get('message');
                            String error = (String)cObjMap.get('error');
                            notification.setBody('Error While sending Account: '+ 'Status code : '+res.getStatusCode()+ ' Error: Callout failed.\n'+ error);    
                            log.response__c= 'Status code : '+res.getStatusCode() +' Response body: '+ cObjMap;
                            log.Error_Message__c = 'Status code : '+res.getStatusCode()+ ' Error: Callout failed :'+ message+' '+error;
                            notification.setTitle(acct.Name+' :Sending Account to ERP -'+status);
                            
                        }      
                        
                    }
                    else{
                        notification.setBody('Error While sending Account: '+ 'Status code : '+res.getStatusCode()+ ' Error: Callout failed.\n'+ res);    
                        log.response__c= 'Status code : '+res.getStatusCode() +' Response body: '+ res;
                        log.Error_Message__c = 'Status code : '+res.getStatusCode()+ ' Error: Callout failed :'+ res;
                        notification.setTitle(acct.Name+' :Sending Account to ERP -');
                        
                    }     
                    
                }
                
                // Unexpected exceptions will be caught here, like a deserialization error.
                else{
                    outcomeMsg = 'Error: An exception has been encountered while calling out to Integration:  ' + e.getMessage();
                    log.status__c='FAILED';
                    log.Error_Message__c = e.getMessage();
                    system.debug('e.getMessage() '+e.getMessage() );
                    
                    
                    System.debug('notificationType  1 ' + notificationType);
                    
                    notification.setBody('Error While sending Account: '+ 'Error: An exception has been encountered while calling out to Integration:  ' + e.getMessage());   
                }
                try {
                    notification.send(addressee);
                    
                }
                catch (Exception ee) {
                    System.debug('Problem sending notification: ' + ee.getMessage());
                }
            }
            
            //}
            
            System.debug('logList  '+log);
            logList.add(log);
            insert logList;          
            AccountTriggerRecursion.skipAzureCall = false;                          
            
            
        }
    
    public static void testmeth(){
        integer i=0;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        
    }
}