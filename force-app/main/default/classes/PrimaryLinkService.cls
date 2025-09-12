public with sharing class PrimaryLinkService {
    public static void deletePrimaryLinks(List<SR_Hedge__c> listOfTrades) {
        Set<Id> tradeIds = new Set<Id>();

        for (SR_Hedge__c trade : listOfTrades) {
            tradeIds.add(trade.Id);
        }

        List<Primary_Trade_Link__c> primaryLinksToDelete = [SELECT Id
            FROM Primary_Trade_Link__c
            WHERE Primary_SR_Hedge__c IN :tradeIds OR Child_SR_Hedge__c IN :tradeIds];

        if (!primaryLinksToDelete.isEmpty()) {
            try {
                //System.debug('DELETE ' + primaryLinksToDelete);

                //delete primaryLinksToDelete;
            } catch (Exception ex) {
                System.debug('Error deleting links');
            }
        }

    }
}