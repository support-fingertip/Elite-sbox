trigger CompetitionTrigger on Competition__c (after insert) {
  if(Trigger.isInsert)
    {
        if(Trigger.isAfter)
        {
            CompetitonTriggerHandler.afterInsert(Trigger.new);
        }
    }
   
}