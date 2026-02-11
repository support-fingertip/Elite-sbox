trigger ContentDocTrigger on ContentDocument (before delete) {
    
    if(trigger.isDelete)
    {
        ContentDocTriggerHandler.beforeDelete( Trigger.old);
    }
    
}