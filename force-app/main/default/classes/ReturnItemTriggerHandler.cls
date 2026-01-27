public class ReturnItemTriggerHandler {
    public static void beforeInsert(list<Return_Item__c> newReturnItems)
    {
        Set<String> keySet = new Set<String>();
        for(Return_Item__c rtn: newReturnItems)
        {
            rtn.Customer_Type__c = rtn.Customer_Type_formula__c;
            String key = rtn.DistributorId__c + '_' + rtn.SKU_Name_Formula__c;
            system.debug('rtn.DistributorId__c==>'+rtn.DistributorId__c);
            keySet.add(key);   
            
            //If DSM/TSE Creates Secondary Return 
            if(rtn.Customer_Type_formula__c =='Secondary Customer' && rtn.Nonsaleable_Quantity__c == null && rtn.Saleable_Quantity__c == null 
               && rtn.Quantity__c != null)
            {
                rtn.Nonsaleable_Quantity__c = rtn.Quantity__c;
            }
        }
        
        if(!keySet.isEmpty())
        {
            
            // Step 3: Load existing stocks
            Map<String, Distributor_Stock__c> existingStockMap = new Map<String, Distributor_Stock__c>();
            for (Distributor_Stock__c stock : [
                SELECT Id, Product__c, Distributor__c, DistributorWithProduct__c
                FROM Distributor_Stock__c
                WHERE DistributorWithProduct__c IN :keySet
            ]) {
                existingStockMap.put(stock.DistributorWithProduct__c, stock);
            }
            
            // Step 4: Create new stock records if needed
            List<Distributor_Stock__c> newStocks = new List<Distributor_Stock__c>();
            for (Return_Item__c item : newReturnItems) {
                
                // Check if stock exists, else create new stock
                String key = item.DistributorId__c + '_' + item.SKU_Name_Formula__c;
                if (existingStockMap.containsKey(key)) {
                    item.Distributor_Stock__c = existingStockMap.get(key).Id;
                } else {
                    Distributor_Stock__c newStock = new Distributor_Stock__c(
                        Product__c = item.SKU__c,
                        Distributor__c = item.DistributorId__c
                    );
                    newStocks.add(newStock);
                    existingStockMap.put(key, newStock);
                }
            }
            
            // Step 5: Insert new stocks if any
            if (!newStocks.isEmpty()) {
                insert newStocks;
                for (Distributor_Stock__c stock : newStocks) {
                    String key = stock.Distributor__c + '_' + stock.Product_Name__c;
                    existingStockMap.put(key, stock);
                }
                
                // Update Distributor Stock reference in items
                for (Return_Item__c item : newReturnItems) {
                    String key = item.DistributorId__c + '_' + item.SKU_Name_Formula__c;
                    item.Distributor_Stock__c = existingStockMap.get(key).Id;
                    
                    system.debug('Customer type=='+item.Customer_Type_formula__c);
                }
            }
            
        }
    }
}