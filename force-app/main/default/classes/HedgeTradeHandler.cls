public class HedgeTradeHandler {
    
    
    public void beforeInsert(List<SR_Hedge__c> trades, Boolean isBefore, Boolean isAfter) {
        updatePrimaryTradeField(trades, isBefore,isAfter);
    }
    
    public void handleProfits(List<SR_Hedge__c> trades) {
        System.debug('handle profits, api call');
        for (SR_Hedge__c trade : trades) {
            system.debug(trade.Close_Date_Time__c.dateGMT() + '/' + trade.Close_Date_Time__c.getTime());
            
            FetchExchangeRateAPI.convertAmount();
        }
    }
    
    public void updatePrimaryTradeField(List<SR_Hedge__c> trades, Boolean isBefore, Boolean isAfter) {
        Set<String> currencies = new Set<String>();
        for (SR_Hedge__c trade : trades) {
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
        for (SR_Hedge__c trade : trades) {
            if (!openTradesByCurrency.containsKey(trade.Currency__c)) {
                if (isBefore) {
                    trade.Primary_Trade__c = true;
                    tradesToUpdate.add(trade);
                }
            } else {
                if (isAfter) {
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
    }

}