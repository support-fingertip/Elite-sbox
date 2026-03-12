trigger VisitFormTrigger on Visit_Form__c (after insert, after delete, after undelete) {

    if (Trigger.isInsert) {
        if (Trigger.isAfter) {
            VisitFormTriggerHandler.afterInsert(Trigger.new);
        }
    }
    else if (Trigger.isUndelete) {
        if (Trigger.isAfter) {
            VisitFormTriggerHandler.afterInsert(Trigger.new);
        }
    }
    else if (Trigger.isDelete) {
        if (Trigger.isAfter) {
            VisitFormTriggerHandler.afterDelete(Trigger.old);
        }
    }
}