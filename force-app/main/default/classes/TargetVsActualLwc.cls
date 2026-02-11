public class TargetVsActualLwc 
{
  /*  public class DataBox{
        @AuraEnabled
        public  list<user> userList;
        @AuraEnabled
        public List<period__c> periodsList;
        @AuraEnabled
        public List<period__c> currentPeriods;
        @AuraEnabled
        public string period;
        @AuraEnabled
        public string userProfileName;
        @AuraEnabled
        public List<Target_Logic__c> targetLogics;
        @AuraEnabled
        public string currentUserId;
        @AuraEnabled
        public List<Target_Item__c> targetItems; 
        @AuraEnabled
        public String initialTargetAssignmentProfile; 
        @AuraEnabled
        public  Map<Id, Decimal> parentToTotalTargetValueMap;
    }
    
    @AuraEnabled //When Intial Loading
    public static DataBox getAllData(){
        DataBox dx = new DataBox();
     
        //Getting all the subodinates of current user
        Set<ID> UserIds = RoleHeirarchyUtility.getRoleSubordinateUsers(UserInfo.getUserId()); 
        dx.initialTargetAssignmentProfile = label.Initial_Target_Assignment_Profile;
        //Getting the heirachy number to query the users from that number
        User userRecord = [select id,Heirarchial_Number__c from user where Profile.Name =:dx.initialTargetAssignmentProfile limit 1];
        decimal heirarchialNumber = userRecord.Heirarchial_Number__c;
        
		//If Target Assignment starts from RSM then it will show from RSM and below user names
        dx.userList = [select Id,Name,ManagerId,Manager.ManagerId,Profile.Name from User where id in:UserIds
                       and Heirarchial_Number__c <=: heirarchialNumber and isactive = true order by Heirarchial_Number__c DESC];
        
	
       // Check if the current user exists in the userList
        Boolean isCurrentUserPresent = false;
        for (User u : dx.userList) {
            if (u.Id == UserInfo.getUserId()) {
                isCurrentUserPresent = true;
                break;
            }
        }
        //We are checking whether current user is existed on the user list if not existed in UI we will not select User in on load
        dx.currentUserId = isCurrentUserPresent ? UserInfo.getUserId() : '';
        
        dx.periodsList = [select id, name,Start_Date__c,End_Date__c from period__c order by Createddate desc limit 12];
        dx.period = [select id  from Period__c where Start_Date__c <= TODAY and End_Date__c>= TODAY  limit 1].Id;
       
        //Based on UserIds we are querig realted Target items
        dx.targetItems = [select Id,Target__c,Target_Value__c,Actual_Value__c,Self_Target__c,Team_s_Actual__c,
                                      Team_s_Target__c,Total_Actual__c,Target_Logic__c,Weighted_Achievement_Percentage__c,Amount__c,
                                      Target_Logic__r.Name,Achieved_Percentage__c,Target__r.Executive__c,Executive_Id__c,
                                      Target__r.Executive__r.Name,Parent__c,Account__c,Account_Id__c,Account__r.Name,Target__r.Period__c 
                                      from Target_Item__c where Target_Logic__r.isActive__c =true and 
                                      (Target__r.Period__c =:dx.period or Parent__r.Target__r.Period__c =:dx.period)
                                      and (Target__r.Executive__c IN:UserIds) order by Target_Logic__r.Name];
        
        //Quering from current month to Current financial year periods 
        Datetime currentDatetime = System.now();
        Integer currentYear = currentDatetime.year();  
        integer cuMonth=System.today().month();
        Date startYear = Date.newInstance(currentYear, cuMonth, 1);        
        //Here assume Current month is 3 then if current year is 2025 currentYear will be 2024
        //in endYear year will get 2025 march
        //if it is 4 then if current year is 2025 endYear will be 2026 march
        if(cuMonth<4){
            currentYear=currentYear-1;
        }
        Date endYear = Date.newInstance(currentYear + 1, 3, 31);
        
        
        dx.currentPeriods = [select id, name from period__c where Start_Date__c >= :startYear AND end_Date__c <= :endYear  order by Createddate ];
        return dx;
    } 
    
    @AuraEnabled //when Period Changes
    public static List<Target_Item__c> getTargetActuals(String period,String userId){
        if(period == null || period == ''){
            period = [select id  from Period__c where Start_Date__c <= TODAY and End_Date__c>= TODAY].Id;
        }
        string currentUserId = userId != null && userId !='' ? userId: UserInfo.getUserId();
        Set<ID> UserIds = RoleHeirarchyUtility.getRoleSubordinateUsers(currentUserId);  
        List<Target_Item__c> items = [select Id,Target__c,Target_Value__c,Actual_Value__c,Self_Target__c,Team_s_Actual__c,
                                      Team_s_Target__c,Total_Actual__c,Target_Logic__c,Weighted_Achievement_Percentage__c,Amount__c,
                                      Target_Logic__r.Name,Achieved_Percentage__c,Target__r.Executive__c,Executive_Id__c,
                                      Target__r.Executive__r.Name,Parent__c,Account__c,Account_Id__c,Account__r.Name,Target__r.Period__c 
                                      from Target_Item__c where Target_Logic__r.isActive__c =true and 
                                      (Target__r.Period__c =:period or Parent__r.Target__r.Period__c =:period)
                                      and (Target__r.Executive__c IN:UserIds) order by Target_Logic__r.Name];
        
        return items;
        
    }
    
    @AuraEnabled //when Indivial target Loading
    public static DataBox getUserTargets(String period,String userId){
        system.debug('period---------->'+period);
        system.debug('userId--------->'+userId);
        DataBox dx = new DataBox();
        if(period == null || period == ''){
            period = [select id  from Period__c where Start_Date__c <= TODAY and End_Date__c>= TODAY].Id;
        }
        
        Employee__c currentEmpRec = [select Id,Name,User__c,Region__c,Division__c from Employee__c where User__c =:userId limit 1];    
        
        //For current user if Region and division existed then we are quering the target logics based on region and divison
        list<Target_Logic__c> targetLogicsList = new list<Target_Logic__c>();
        if(currentEmpRec != null && currentEmpRec.Region__c != null && currentEmpRec.Division__c != null)
        {
            targetLogicsList =  [SELECT Id, Name, Target_Type__c, Object__c,Field__c, SOQL_Query__c, Formula__c, Product__c,
                                Product_Category__c, Account_Type__c,Selling_Category__c
                                FROM Target_Logic__c where isActive__c=true and Target_Plan__c != null and
                                Target_Plan__r.Division__c =:currentEmpRec.Division__c and  Target_Plan__r.Region__c =:currentEmpRec.Region__c 
                                and Target_Plan__r.Active__c = true order by Name];
             system.debug('targetLogicsList--------->'+targetLogicsList);  
        }
     
        dx.targetLogics = targetLogicsList;
        dx.targetItems = [select Id,Target__c,Target_Value__c,Actual_Value__c,Self_Target__c,Team_s_Actual__c,
                          Team_s_Target__c,Total_Actual__c,Target_Logic__c,Weighted_Achievement_Percentage__c,Amount__c,
                          Target_Logic__r.Name,Achieved_Percentage__c,Target__r.Executive__c,Executive_Id__c,
                                      Target__r.Executive__r.Name,Parent__c,Account__c,Account_Id__c,Account__r.Name,Target__r.Period__c 
                                      from Target_Item__c where Target_Logic__r.isActive__c =true and 
                                      (Target__r.Period__c =:period or Parent__r.Target__r.Period__c =:period)
                                      and (Target__r.Executive__c =: userId) order by Target_Logic__r.Name];
        
        
        //If Taget distribution happend from this user we will restict the decrsing target value 
        if(!dx.targetItems.isEmpty())
        {
            // Create list of parent IDs from targetItems
            List<Id> parentIds = new List<Id>();
            for (Target_Item__c ti :  dx.targetItems) {
                parentIds.add(ti.Id);
            }
            
            // Create Map for Parent ID and Total Target_Value__c from Child Items
            Map<Id, Decimal> parentToTotalTargetValueMap = new Map<Id, Decimal>();
            
            if (!parentIds.isEmpty()) {
                AggregateResult[] groupedResults = [
                    SELECT Parent__c, SUM(Target_Value__c) totalTargetValue 
                    FROM Target_Item__c 
                    WHERE Parent__c IN :parentIds 
                    GROUP BY Parent__c
                ];
                
                for (AggregateResult ar : groupedResults) {
                    Id parentId = (Id) ar.get('Parent__c');
                    Decimal totalValue = (Decimal) ar.get('totalTargetValue');
                    parentToTotalTargetValueMap.put(parentId, totalValue);
                }
            }
            dx.parentToTotalTargetValueMap =parentToTotalTargetValueMap;
            
            system.debug('Parent to Total Target Value Map: ' + parentToTotalTargetValueMap);
        }
        
        
        return dx;
        
    }
    
    @AuraEnabled //Save Subodinated Target Items
    public static List<Target_Item__c> saveTargets(String targetList, string selctdperiod){ 
        List<Target_Item__c> targetItemList = (List<Target_Item__c>)JSON.deserialize( targetList, List<Target_Item__c>.class);
        system.debug('Selected Period'+selctdperiod);
        system.debug('targetItemList' +targetItemList);
        system.debug(targetItemList.size());
        string currentUserId = UserInfo.getUserId();
        Set<ID> UserIds = RoleHeirarchyUtility.getRoleSubordinateUsers(currentUserId); 
        
        //Selected Period Targets we are fetching -- User --> Target Record map we are creating
        Map<String,Target__c> targetsMap = new Map<String,Target__c>();
        for(Target__c tr:[select Id,Name,Executive__c,Period__c from Target__c where Executive__c IN:UserIds and Period__c =:selctdperiod ]){
            targetsMap.put(tr.Executive__c, tr);
        }
        
       
        List<Target_Item__c> itemsToUpdate = new  List<Target_Item__c>();
        map<string,Target__c> newTarget = new  map<string,Target__c>();
        List<Target_Item__c> trgsToBeCreated = new  List<Target_Item__c>();
        
        for(Target_Item__c itm:targetItemList){
            if(itm.Target_Value__c != null && itm.Target_Value__c != 0){
                Target_Item__c item1 = new Target_Item__c();
                item1.Target_Logic__c = itm.Target_Logic__c;
                item1.Target_Value__c = itm.Target_Value__c;
                item1.Parent__c = itm.Parent__c;
                if(itm.Executive_Id__c != null)
                {
                   item1.ownerId = itm.Executive_Id__c;
                }
                
                //If Alredy This Item is existed and and when we updated any target value             
                if(itm.Id != null){
                    item1.Id = itm.Id;
                }
               
                
 				//For this Target item already a "Traget" existed 
                if(targetsMap.containsKey(itm.Executive_Id__c)){
                    if(itm.Target__c == null)
                    {
                        item1.Target__c = targetsMap.get(itm.Executive_Id__c).Id;
                    }
                    itemsToUpdate.add(item1);
                }
                else{
                    trgsToBeCreated.add(item1);
                    if(!newTarget.containsKey(itm.Executive_Id__c) && !targetsMap.containsKey(itm.Executive_Id__c)){
                        Target__c tr = new Target__c();
                        tr.Executive__c = itm.Executive_Id__c;
                        if(itm.Executive_Id__c != null)
                        {
                            tr.ownerId = itm.Executive_Id__c;
                        }
                        tr.Period__c = selctdperiod;
                        system.debug(tr.ownerId +'='+ itm.Executive_Id__c);  
                        newTarget.put(itm.Executive_Id__c,tr);
                    }
                }
            }
        }  
        if(itemsToUpdate.size()>0)
        {
            //here we are updating old Target Items.
            upsert itemsToUpdate;
        }
        
        
        //here we are creating Target Records for New TargetItems.
        database.upsert(newTarget.values(),false);
       
        targetsMap.clear();
        itemsToUpdate.clear();
        
        for(Target__c tr:[select Id,Name,Executive__c,Period__c from Target__c where Executive__c IN:UserIds and Period__c =:selctdperiod ]){
            targetsMap.put(tr.Executive__c, tr);
        }
        //here for new TargetItems we are adding inserted target rec id 
        for(Target_Item__c itm : trgsToBeCreated){
            if(targetsMap.containsKey(itm.ownerId))
            {
                itm.Target__c = targetsMap.get(itm.ownerId).Id;
            }
            itemsToUpdate.add(itm);
        }

        //here we are inserting New Target Items.
        upsert itemsToUpdate;
        
        List<Target_Item__c> items = [  select Id,Target__c,Target_Value__c, Actual_Value__c,Self_Target__c,Team_s_Actual__c,
                                      Team_s_Target__c,Total_Actual__c,Target_Logic__c,Weighted_Achievement_Percentage__c,Amount__c,
                                      Target_Logic__r.Name,Achieved_Percentage__c,Target__r.Executive__c,Executive_Id__c,
                                      Target__r.Executive__r.Name,Parent__c,Account__c,Account_Id__c,
                                      Account__r.Name,Account__r.Customer_Preference__c from Target_Item__c where 
                                      (Target__r.Period__c =:selctdperiod or Parent__r.Target__r.Period__c =:selctdperiod)
                                      and (Target__r.Executive__c IN:UserIds ) order by Target_Logic__r.Name];
        
      
        return items;
        
    }
    
    @AuraEnabled //Save User Indivial Targets
    public static List<Target_Item__c> saveAdminTargets(List<Target_Item__c> targetItems,string selectedAdminPeriod,string selectedPeriod,string userId) {
        system.debug('targetItems '+targetItems);
        system.debug('selectedAdminPeriod '+selectedAdminPeriod);
        if(targetItems.size()>0){
            list<target__c> tar=[select id,executive__c from target__c where period__c=:selectedAdminPeriod and executive__c=:userId];
            system.debug('tar 64'+ tar);
            if(tar.size()==0){
                target__c tr= new target__c();
                tr.Executive__c=userId;
                tr.Period__c=selectedAdminPeriod;
                tr.OwnerId =userId;
                insert tr;
                tar=[select id,executive__c from target__c where period__c=:selectedAdminPeriod and executive__c=:userId];
                system.debug(tar);
            }
            for(Target_Item__c tt:targetItems ){
                if(tt.target__c== null){  
                    tt.target__c=tar[0].id;
                    tt.OwnerId =userId;
                    tt.Actual_Value__c = 0; //for new Target Items we are setting the actual value as Zero
                }
            }
            system.debug('118 targetItems '+targetItems);
            upsert targetItems;
        }
      
        //Getting all the subodinates of current user
        Set<ID> UserIds = RoleHeirarchyUtility.getRoleSubordinateUsers(UserInfo.getUserId()); 
        
        List<Target_Item__c> items = [select Id,Target__c,Target_Value__c,Actual_Value__c,Self_Target__c,Team_s_Actual__c,
                                      Team_s_Target__c,Total_Actual__c,Target_Logic__c,Weighted_Achievement_Percentage__c,Amount__c,
                                      Target_Logic__r.Name,Achieved_Percentage__c,Target__r.Executive__c,Executive_Id__c,
                                      Target__r.Executive__r.Name,Parent__c,Account__c,Account_Id__c,Account__r.Name,Target__r.Period__c 
                                      from Target_Item__c where Target_Logic__r.isActive__c =true and 
                                      (Target__r.Period__c =:selectedPeriod or Parent__r.Target__r.Period__c =:selectedPeriod)
                                      and (Target__r.Executive__c =: UserIds) order by Target_Logic__r.Name];
        
        return items;
        
    }
    */
}