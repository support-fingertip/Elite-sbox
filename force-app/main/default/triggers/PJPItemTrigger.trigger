trigger PJPItemTrigger on PJP_Item__c (before insert, before update) {
    
    if(Label.Enable_PJPItem_Trigger == 'TRUE'){
        if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
            PJPItemHandler.autoApprovePJPForAdminOrManager(Trigger.new);
            PJPItemHandler.handleValidations(Trigger.new);
        }
    }
    
    
}