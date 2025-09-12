public with sharing class TechnicalAnalysisTradesDataController {
    public TechnicalAnalysisTradesDataController() {

    }

    @AuraEnabled (cacheable=true)
    public static List<Technical_Analysis_Trade__c> getAllTechnicalAnalysisTradesOpen(){
        return [SELECT Id, Name, Open_Price__c, Stage__c, Symbol__c, Stop_Loss_Price__c, Take_Profit_Price__c, CreatedDate, Profit__c, Close_Date_Time__c
                FROM Technical_Analysis_Trade__c 
                WHERE Stage__c = 'O'
                ORDER BY CreatedDate ASC];       
    }

    @AuraEnabled (cacheable=true)
    public static List<Technical_Analysis_Trade__c> getAllTechnicalAnalysisTrades(){
        return [SELECT Id, Name, Open_Price__c, Stage__c, Symbol__c, Stop_Loss_Price__c, Take_Profit_Price__c, CreatedDate, Profit__c, Close_Date_Time__c
                FROM Technical_Analysis_Trade__c];       
    }
}