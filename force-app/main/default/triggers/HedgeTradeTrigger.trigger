trigger HedgeTradeTrigger on SR_Hedge__c (before insert, after insert, before update) {
    
    HedgeTradeHandler tradesHandler = new HedgeTradeHandler();
    /*if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            tradesHandler.beforeInsert(Trigger.New);
        }
       //tradesHandler.handleProfits(Trigger.New);
    }*/
    
    //Fix CODE BELOW
    //Make handler UPDATE, AWFUL PRACTISE!!!!!
    /*            system.debug('update trade');
    List<SR_Hedge__c> toUpdate = new List<SR_Hedge__c>();
    List<Primary_Trade_Link__c> toUpdateLinks = new List<Primary_Trade_Link__c>();
    */
    //Get all open and map trade to name (string, object)
    //loop throuhg all trads if
    //
    //if (Trigger.isBefore) {
    Set<String> currencies = new Set<String>();
    for (SR_Hedge__c trade : Trigger.new) {
        currencies.add(trade.Currency__c);
    }
    
    // Query for all open trades with currencies in the set
    Map<String, List<SR_Hedge__c>> openTradesByCurrency = new Map<String, List<SR_Hedge__c>>();
    for (SR_Hedge__c openTrade : [
        SELECT Id, Currency__c, Status__c 
        FROM SR_Hedge__c 
        WHERE Currency__c IN :currencies AND Status__c = 'Open'
    ]) {
        if (!openTradesByCurrency.containsKey(openTrade.Currency__c)) {
            openTradesByCurrency.put(openTrade.Currency__c, new List<SR_Hedge__c>());
        }
        openTradesByCurrency.get(openTrade.Currency__c).add(openTrade);
    }
    
    // Query for the most recent primary trade for each currency
    Map<String, SR_Hedge__c> mostRecentPrimaryByCurrency = new Map<String, SR_Hedge__c>();
    for (SR_Hedge__c primaryTrade : [
        SELECT Id, Currency__c, Name, Primary_Trade__c 
        FROM SR_Hedge__c 
        WHERE Primary_Trade__c = true AND Currency__c IN :currencies 
        ORDER BY Name DESC
    ]) {
        if (!mostRecentPrimaryByCurrency.containsKey(primaryTrade.Currency__c)) {
            mostRecentPrimaryByCurrency.put(primaryTrade.Currency__c, primaryTrade);
        }
    }
    
    // Update the trigger records based on the query results
    List<SR_Hedge__c> tradesToUpdate = new List<SR_Hedge__c>();
    List<Primary_Trade_Link__c> linksToInsert = new List<Primary_Trade_Link__c>();
    for (SR_Hedge__c trade : Trigger.new) {
        if (!openTradesByCurrency.containsKey(trade.Currency__c)) {
            if (Trigger.isBefore) {
                trade.Primary_Trade__c = true;
                tradesToUpdate.add(trade);
            }
        } else {
            if (Trigger.isAfter) {
                SR_Hedge__c mostRecentPrimary = mostRecentPrimaryByCurrency.get(trade.Currency__c);
                if (mostRecentPrimary != null && mostRecentPrimary.Id != trade.Id) {
                    Primary_Trade_Link__c newLink = new Primary_Trade_Link__c(
                        Primary_SR_Hedge__c = mostRecentPrimary.Id,
                        Child_SR_Hedge__c = trade.Id
                    );
                    linksToInsert.add(newLink);
                }
            }
        }
    }
    
    /*if (tradesToUpdate.size() > 0) {
        update tradesToUpdate;
    }*/
    
    if (linksToInsert.size() > 0) {
        insert linksToInsert;
    }
    //}
    /*for (SR_Hedge__c trade : Trigger.new) {
        List<SR_Hedge__c> numberOpenSameSymbol = [SELECT Id, Currency__c, Status__c FROM SR_Hedge__c WHERE Currency__c = :trade.Currency__c AND Status__c = 'Open'];
        //
        system.debug('number open ' + numberOpenSameSymbol.size());
        if (numberOpenSameSymbol.size() == 0) {
            if (Trigger.isBefore) {
            	trade.Primary_Trade__c = true;

            }
            system.debug('update trade to primary');
            //toUpdate.add(trade);
            
        } else {
            
            system.debug('Add new link');
            
            if (Trigger.isAfter) {
                List<SR_Hedge__c> numberOpenSame = [SELECT Id, Currency__c, Name, Primary_Trade__c FROM SR_Hedge__c
                                                WHERE Primary_Trade__c = true AND Currency__c = :trade.Currency__c
                                                Order by Name desc ];
                system.debug(numberOpenSame[0]);
            	system.debug(trade);
                
                if (numberOpenSame[0].Id != trade.Id) {
                    Primary_Trade_Link__c newLink = new Primary_Trade_Link__c(
                        Primary_SR_Hedge__c = numberOpenSame[0].Id,
                        Child_SR_Hedge__c = trade.Id);
                    toUpdateLinks.add(newLink);
                }
            }
        }
        
        
    }
    if (toUpdateLinks.size() != 0) {
        system.debug('update link');
        insert toUpdateLinks;
    }*/
}