trigger AreaTrigger on Area__c (after insert) {
    
    List<Area__c> areasToUpdate = new List<Area__c>();
    
    for(Area__c area : Trigger.new) {
        if(area.Territory_Code__c != null) {
            areasToUpdate.add(new Area__c(
                Id = area.Id,
                Territory_Code_Text__c = String.valueOf(area.Territory_Code__c)
            ));
        }
    }
    
    if(!areasToUpdate.isEmpty()) {
        update areasToUpdate;
    }
}