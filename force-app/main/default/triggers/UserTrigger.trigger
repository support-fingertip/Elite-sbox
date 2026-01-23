trigger UserTrigger on User (before update, after insert) {
 
    
    if(trigger.isInsert ){
        if(trigger.isAfter)
        {
            List<User> usersToUpdate = new List<User>();
            
            for(User usr : Trigger.new) {
                if(usr.User_Id__c != null) {
                    usersToUpdate.add(new User(
                        Id = usr.Id,
                        User_Id_Text__c = String.valueOf(usr.User_Id__c)
                    ));
                }
            }
            
            if(!usersToUpdate.isEmpty()) {
                update usersToUpdate;
            }
        }
    }
    else if(trigger.isUpdate)
    {
        if(trigger.isBefore)
        {
            if(UserTriggerHandler.userdeactivationProcess == false)
            {
                //UserTriggerHandler.handleBeforeUpdate(trigger.new, trigger.oldMap);
            }
           
        }
        
    }
}