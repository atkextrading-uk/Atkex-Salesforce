public with sharing class OpenTradesController {
    @AuraEnabled
    public static List<Trade__c> getTrades() {
        return [SELECT Name, Symbol__c
                FROM Trade__c
                WHERE Progress__c = 'Open'];
    }

}