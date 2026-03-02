/****************************************************************
 * Trigger Name : LeavesTrigger
 * Object       : Leaves__c
 * Description  : leave logic via LeavesTriggerHandler.
 ****************************************************************/
trigger LeavesTrigger on Leaves__c (before insert, before update, after insert, after update) {
    
    if (Trigger.isInsert) {
        if (Trigger.isBefore) {
            LeavesTriggerHandler.handleBeforeInsert(Trigger.new);
        } else if (Trigger.isAfter) {
            LeavesTriggerHandler.handleAfterInsert(Trigger.new);
        }
    } 
    
    else if (Trigger.isUpdate) {
        if (Trigger.isBefore) {
            LeavesTriggerHandler.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
        } else if (Trigger.isAfter) {
            // New call for cancellation emails
            LeavesTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}