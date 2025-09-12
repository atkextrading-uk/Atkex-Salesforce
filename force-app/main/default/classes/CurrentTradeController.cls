public with sharing class CurrentTradeController {

    @AuraEnabled(Cacheable=true)
    public static SR_Hedge__C getCurrentTradeURLS(String id) {
        SR_Hedge__C returnTrade = [SELECT id, Open_Screenshot__c, Close_Screenshot__c FROM SR_HEDGE__C WHERE id = :id];
        return returnTrade;
    }
}