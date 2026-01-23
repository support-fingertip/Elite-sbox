/****************************************************************
* Class Name : NewBeatController
* Company : Fingertipplus
* Created Date : 09-05-2025
* @description : This class handles beat creation and assignments
* @author : Mayuri Patel
* Used By : - beatFormPage
* Change Log:
* -----------------------------------------------------------------------------
* Ver   | Author          | Date        | Description
* -----------------------------------------------------------------------------
* 1.0   | Mayuri Patel    | 09-05-2025  | Initial version
* -----------------------------------------------------------------------------
******************************************************************/
public with sharing class NewBeatController {

    public class mainData{
        @AuraEnabled public List<String> regionPickList { get; set; }
        @AuraEnabled public List<String> custTypePickList { get; set; }
        @AuraEnabled public List<Account> accounts {get; set;}
        @AuraEnabled public User LoggedInUser { get; set; }
        @AuraEnabled public List<User> users {get; set;}
        @AuraEnabled public Child_beat__c beat {get; set;}
        @AuraEnabled public String beatId {get; set;}
        @AuraEnabled public List<Junction_Beat__c> beatItems {get; set;}
        @AuraEnabled public List<Beat_Assignment__c> assignments {get; set;}
    }

    @AuraEnabled public static mainData getValues(){
        mainData dt = new mainData();

        dt.regionPickList = getPicklistValues('Account','Region__c');
        dt.custTypePickList = getPicklistValues('Account','Customer_Type__c');
        dt.LoggedInUser = [Select id,name,Profile.Name from user where id =:userinfo.getUserId() ];

        return dt;

    }

    @AuraEnabled public static mainData getData(String region){

        mainData dt = new mainData();

        List<Account> accList = [SELECT Id, Name, Area__c, City__c, Customer_Category__c,createdDate,Region__c,Division__c,
                                Phone,Primary_Phone_Number__c, Customer_Type__c 
                                 FROM Account where Region__c=:region  order by Name asc];

        dt.users = [
            SELECT Id, Name, Username, Region__c,Profile.Name
            FROM User
            WHERE IsActive = TRUE AND ID IN (select Exectuive__c from Product_Mapping__c where Customer__c IN :accList)
            ORDER BY Name ASC
        ];

        dt.accounts = accList;

        return dt;

    }

    @AuraEnabled
    public static mainData getUserData() {
        mainData data = new mainData();

        data.users = [
            SELECT Id, Name, Username, Region__c
            FROM User
            WHERE IsActive = TRUE
            ORDER BY Name ASC
        ];
        data.regionPickList = getPicklistValues('User', 'Region__c');
         data.LoggedInUser = [Select id,name,Profile.Name from user where id =:userinfo.getUserId() ];

        return data;
    }

    @AuraEnabled
    public static mainData getAccountMap(String userId) {
        mainData data = new mainData();
         List<Account> accList = [SELECT Id, Name, Area__c, City__c, Customer_Category__c,createdDate,Region__c,Division__c,
                                Phone,Primary_Phone_Number__c, Customer_Type__c 
                                 FROM Account where Id IN  ( SELECT Customer__c
           FROM Product_Mapping__c
          WHERE Exectuive__c = :userId)   order by Name asc];
       
       data.accounts = accList;


        return data;
    }

     @AuraEnabled
    public static mainData getBeatData(String beatId) {
        mainData data = new mainData();

        if(beatId != null){
            data.beat = [select Id,Name,Active__c,Region__c from Child_Beat__c where Id=:beatId];
        
            if(data.beat != null){
                data.beatItems = [select Id,Name,Account__c,Order_Number__c from Junction_Beat__c where Child_Beat__c =:beatId
                                    order by Order_Number__c asc nulls last];

                data.assignments = [select Id,Name,User__c,Beat__c,Order_Number__c from Beat_Assignment__c 
                                    where Beat__c=:beatId order by Order_Number__c asc nulls last];
            }

        }
        data.beatId = beatId;

       
        return data;
    }

     public static List<String> getPicklistValues(String objectName, String fieldName) {
        List<String> picklistValues = new List<String>();

        // Describe the object
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
        Schema.DescribeSObjectResult objDescribe = objType.getDescribe();

        // Describe the field
        Schema.DescribeFieldResult fieldDescribe = objDescribe.fields.getMap().get(fieldName).getDescribe();

        // Get picklist values
        for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
            picklistValues.add(entry.getLabel());
        }
        return picklistValues;
    }

    @AuraEnabled
    public static String isAdminOrTSE() {
        String profileName = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId()].Name;
        if (profileName.contains('System Administrator')) {
            return 'Admin';
        } else if (profileName.contains('TSE')) {
            return 'TSE';
        } else {
            return 'Other';
        }
    }

    @AuraEnabled
    public static mainData saveOrUpdateBeat(String name, String region, Id beatId, List<string> deleteIds,List<Junction_Beat__c> jnB) {
        Child_Beat__c beat;
        if (beatId != null) {
            beat = [SELECT Id FROM Child_Beat__c WHERE Id = :beatId LIMIT 1];
            beat.Name = name;
            beat.Region__c = region;
        } else {
            beat = new Child_Beat__c(Name = name,Region__c=region);
        }
        upsert beat;

        List<Junction_Beat__c> jn = [Select id from Junction_Beat__c where id=:deleteIds];
        system.debug('jun'+jn);
        system.debug('deleteJun'+deleteIds);
        if(!jn.isEmpty()){
            delete jn;
        }

        for(Junction_Beat__c jb: jnB){
            jb.Child_Beat__c = beat.Id;
        }

        upsert jnB;

        return getBeatData(beat.Id);
    }

    @AuraEnabled
    public static mainData upsertAssignments(Id beatId, List<string> deleteIds,List<Beat_Assignment__c> jnB) {
        
        List<Beat_Assignment__c> jn = [Select id from Beat_Assignment__c where id=:deleteIds];
        system.debug('jun'+jn);
        system.debug('deleteJun'+deleteIds);
        if(!jn.isEmpty()){
            delete jn;
        }

        for(Beat_Assignment__c jb: jnB){
            jb.Beat__c = beatId;
        }

        upsert jnB;

        return getBeatData(beatId);
    }

    @AuraEnabled
    public static void upsertJunctions(Id beatId, List<Id> accountIds) {
        List<Junction_Beat__c> inserts = new List<Junction_Beat__c>();
        for (Id accId : accountIds) {
            inserts.add(new Junction_Beat__c(Child_beat__c = beatId, Account__c = accId));
        }
        upsert inserts;
    }

    @AuraEnabled
    public static List<Junction_Beat__c> getExistingBeatAccounts(Id beatId) {
        return [SELECT Id, Account__c, Account__r.Name FROM Junction_Beat__c WHERE Child_beat__c = :beatId];
    }

    @AuraEnabled
    public static void deleteJunctionBeat(Id junctionId) {
        Junction_Beat__c jb = [SELECT Id FROM Junction_Beat__c WHERE Id = :junctionId LIMIT 1];
        delete jb;
    }

    @AuraEnabled
    public static String getBeatName(Id beatId) {
        return [SELECT Name FROM Child_Beat__c WHERE Id = :beatId LIMIT 1].Name;
    }
    
    @AuraEnabled
    public static List<User> getFilteredUsers(String name, String username, String region) {
        String query = 'SELECT Id, Name, Username, Region__c FROM User WHERE IsActive = TRUE';
        if (String.isNotBlank(name)) {
            query += ' AND Name LIKE :(%' + name + '%)';
                }
        if (String.isNotBlank(username)) {
            query += ' AND Username LIKE :(%' + username + '%)';
                }
        if (String.isNotBlank(region)) {
            query += ' AND Region__c LIKE :(%' + region + '%)';
                }
        return Database.query(query);
    }


    
   /* @AuraEnabled
    public static void upsertAssignments(Id beatId, List<Id> userIds) {
        List<Beat_Assignment__c> assignments = new List<Beat_Assignment__c>();
        Integer index = 1;
        for (Id userId : userIds) {
            assignments.add(new Beat_Assignment__c(
                Beat__c = beatId,
                User__c = userId,
                Order_Number__c = index++,
                Active__c = 'Yes'
            ));
        }
        upsert assignments;
    }

    

     @AuraEnabled
    public static Id saveOrUpdateBeat(String name, Id beatId) {
        Child_Beat__c beat;
        if (beatId != null) {
            beat = [SELECT Id FROM Child_Beat__c WHERE Id = :beatId LIMIT 1];
            beat.Name = name;
        } else {
            beat = new Child_Beat__c(Name = name);
        }
        upsert beat;
        return beat.Id;
    }
 
    @AuraEnabled
    public static List<Account> getFilteredAccounts(String name, String customerType, String region) {
        String query = 'SELECT Id, Name, Customer_Type__c, Region__c FROM Account WHERE Id != null';
        if (String.isNotBlank(name)) {
            query += ' AND Name LIKE :name';
        }
        if (String.isNotBlank(customerType)) {
            query += ' AND Customer_Type__c LIKE :customerType';
        }
        if (String.isNotBlank(region)) {
            query += ' AND Region__c LIKE :region';
        }
        return Database.query(query);
    }
*/

}