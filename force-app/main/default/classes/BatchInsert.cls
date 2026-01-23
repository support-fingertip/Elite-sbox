/*
*********************************************************
Apex Class Name    : BatchInsert
Created Date       : Apr 16, 2024
@description       : This Batch is used to insert bulk records uploaded by CSV file. Batch is executed from "CSVCreator" class.
@author            : Mayuri Patel
Modification Log:
Ver   Date         Author                  Modification
1.0   16-04-2024   Mayuri Patel            Initial Version
*********************************************************
*/
global class BatchInsert implements Database.Batchable<SObject>, Database.Stateful {
  global List<sObject> records;
  global Map<String, String> errorMap;
  global Map<String, SObject> IdToSObjectMap;
  global Map<String, String> successMap;
  global String baseURL;
  global String objectName;
  global String csvStr;
  global Schema.SObjectField externalId;

  global BatchInsert() {
  }

  global BatchInsert(
    List<sObject> source,
    Schema.SObjectField externalId,
    String objectName,
    String csvStr
  ) {
    errorMap = new Map<String, String>();
    successMap = new Map<String, String>();
    IdToSObjectMap = new Map<String, SObject>();
    baseURL = URL.getOrgDomainUrl().toExternalForm();
    system.debug(source.size());
    records = source;
    this.externalId = externalId;
    this.objectName = objectName;
    this.csvStr = csvStr;
  }
  global List<sObject> start(Database.BatchableContext context) {
    return records;
  }
  global void execute(Database.BatchableContext context, List<sObject> scope) {
    // Database.insert(scope, false);

    system.debug(scope.size());
    if (scope.size() > 0) {
      List<Database.upsertResult> dsrs = Database.Upsert(
        scope,
        externalId,
        false
      );
      Integer index = 0;
      String recordId = '';
      for (Database.upsertResult dsr : dsrs) {
        system.debug(dsr);
        if (!dsr.isSuccess()) {
          String errMsg = dsr.getErrors()[0].getMessage();

          recordId = errMsg.substringAfter('record with id: ')
            .substringBefore(';');
          System.debug('Duplicate record ID: ' + recordId);
          if (recordId == null || recordId == '')
            recordId = String.valueof(index + 1);
          errorMap.put(recordId, errMsg);
        } else {
          recordId = (scope[index].Id != null)
            ? scope[index].Id
            : String.valueof(index + 1);
          String sucMsg = baseURL + '/' + recordId;
          successMap.put(recordId, sucMsg);
        }
        IdToSObjectMap.put(recordId, scope[index]);
        system.debug(IdToSObjectMap);
        index++;
      }
    }
  }
  global void finish(Database.BatchableContext context) {
    system.debug(IdToSObjectMap);
    system.debug(IdToSObjectMap.size());
    if (!IdToSObjectMap.isEmpty()) {
      //Send an email to the User after your batch completes
      AsyncApexJob a = [
        SELECT
          id,
          ApexClassId,
          JobItemsProcessed,
          TotalJobItems,
          NumberOfErrors,
          CreatedBy.Email
        FROM AsyncApexJob
        WHERE id = :context.getJobId()
      ];
      String body =
        'Your batch job ' +
        a.Id +
        'has finished. \n' +
        'There were total' +
        IdToSObjectMap.size() +
        ' records. Please find the attached success and error records CSV.';
      String subject = 'Apex Batch Result for ApexJob: ' + a.Id;
      // Define the email
      Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
      // Define email file attachment list
      Messaging.EmailFileAttachment[] emailAttList = new List<Messaging.EmailFileAttachment>();
      if (!errorMap.isEmpty()) {
        // Creating the CSV file for error
        String finalstr = 'Record Number, Success, Created, Error \n';

        String attName =
          'Errors' +
          system.now().format('YYYYMMDDhhmm') +
          '.csv';
        for (String id : errorMap.keySet()) {
          string err = errorMap.get(id);
          // Account acct = (Account) IdToSObjectMap.get(id);
          string recordString = '"' + id + '","FALSE","FALSE","' + err + '"\n';
          finalstr = finalstr + recordString;
        }

        // Create the email attachment
        Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
        efa.setFileName(attName);
        efa.setBody(Blob.valueOf(finalstr));
        emailAttList.add(efa);
      }
      if (!successMap.isEmpty()) {
        // Creating the CSV file for successful updates
        String finalstr = 'Id, Success, Created, Link \n';
        String attName =
          'Success' +
          system.now().format('YYYYMMDDhhmm') +
          '.csv';
        for (String id : successMap.keySet()) {
          string suc = successMap.get(id);
          //Account acct = (Account) IdToSObjectMap.get(id);
          string recordString = '"' + id + '","TRUE","TRUE","' + suc + '"\n';
          finalstr = finalstr + recordString;
        }

        // Create the email attachment
        Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
        efa.setFileName(attName);
        efa.setBody(Blob.valueOf(finalstr));
        emailAttList.add(efa);
      }
      // Sets the paramaters of the email
      email.setSubject(subject);
      email.setToAddresses(
        new List<String>{
          'mayuri.patel@fingertipplus.com' /*,'support.bizom@eliteindia.com','parvathi.iyer@eliteindia.com'*/
        }
      );
      // email.setToAddresses( new String[] {'mayuripatel1505@gmail.com'} );
      email.setPlainTextBody(body);
      email.setFileAttachments(emailAttList);

      DataUpload_Log__c dulog = new DataUpload_Log__c();
      dulog.Upload_Time__c = system.now();
      dulog.Uploaded_By__c = UserInfo.getUserId();
      dulog.Object__c = objectName;
      dulog.Job_No__c = a.Id;
      dulog.Email__c = email.getPlainTextBody();
      dulog.From__c = UserInfo.getUserEmail();
      dulog.To__c = String.valueof(email.getToAddresses());
      try {
        // Sends the email
        Messaging.SendEmailResult[] r = Messaging.sendEmail(
          new List<Messaging.SingleEmailMessage>{ email }
        );

        insert dulog;

        for (Messaging.EmailFileAttachment att : emailAttList) {
          ContentVersion file = new ContentVersion(
            title = att.getFileName(),
            versionData = att.getBody(),
            pathOnClient = att.getFileName() + '.csv'
          );
          insert file;
          ContentVersion conVer = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :file.Id
            LIMIT 1
          ];
          ContentDocumentLink cdl = new ContentDocumentLink();
          cdl.ContentDocumentId = conVer.ContentDocumentId;
          cdl.ShareType = 'I';
          cdl.Visibility = 'AllUsers';
          cdl.LinkedEntityId = dulog.Id;
          insert cdl;
        }

        ContentVersion file = new ContentVersion(
          title = 'Data File',
          versionData = Blob.valueOf(csvStr),
          pathOnClient = 'Data File.csv'
        );
        insert file;
        ContentVersion conVer = [
          SELECT Id, ContentDocumentId
          FROM ContentVersion
          WHERE Id = :file.Id
          LIMIT 1
        ];
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = conVer.ContentDocumentId;
        cdl.ShareType = 'I';
        cdl.Visibility = 'AllUsers';
        cdl.LinkedEntityId = dulog.Id;
        insert cdl;
      } catch (System.Exception ae) {
        ExceptionHandler.addLog(ae, String.valueOf(email), 'BatchInsert');
        ExceptionHandler.addLog(ae, String.valueOf(dulog), 'BatchInsert');
      }
    }
  }
}