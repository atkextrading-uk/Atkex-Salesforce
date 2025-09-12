public with sharing class SupportResistanceTradesDataController {
    public SupportResistanceTradesDataController() {

    }

    @AuraEnabled (cacheable=true)
    public static List<SR_Hedge__c> getAllTechnicalAnalysisTradesOpen(){
        return [SELECT Id, Name, Currency__r.Name, Status__c, Final_Units_Remaining__c
                FROM SR_Hedge__c 
                WHERE Status__c = 'Open' AND CreatedByID = :UserInfo.getUserId()
                ORDER BY Currency__r.Name ASC];       
    }

    @AuraEnabled (cacheable=true)
    public static List<SR_Hedge__c> getAllTechnicalAnalysisTrades(){
        return [SELECT Id, Name, Currency__r.Name, Status__c, Final_Units_Remaining__c
                FROM SR_Hedge__c];   
    }
}