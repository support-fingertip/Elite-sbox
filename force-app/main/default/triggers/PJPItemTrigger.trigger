trigger PJPItemTrigger on PJP_Item__c (before insert, before update) {
    
    if(Label.Enable_PJPItem_Trigger == 'TRUE'){
        if (Trigger.isBefore && Trigger.isInsert) {
            PJPItemHandler.autoApprovePJPForAdminOrManager(Trigger.new);
            PJPItemHandler.handleValidations(Trigger.new);
        }
        else if (Trigger.isBefore && Trigger.isUpdate) {
            PJPItemHandler.handleValidations(Trigger.new);
        }
    }
    
    
}