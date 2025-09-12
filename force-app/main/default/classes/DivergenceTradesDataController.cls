public class DivergenceTradesDataController {
    

    @AuraEnabled (cacheable=true)
    public static List<Hidden_Divergence_Trade__c> getAllDivergenceTradesOpen(){
        return [SELECT Id, Name, Open_Price__c, Stage__c, Symbol__c, Stop_Loss_Price__c, Take_Profit_Price__c, CreatedDate, Profit__c, Close_Date_Time__c
                FROM Hidden_Divergence_Trade__c 
                WHERE Stage__c = 'O'
                ORDER BY CreatedDate ASC];       
    }

    @AuraEnabled (cacheable=true)
    public static List<Hidden_Divergence_Trade__c> getAllDivergenceTrades(){
        return [SELECT Id, Name, Open_Price__c, Stage__c, Symbol__c, Stop_Loss_Price__c, Take_Profit_Price__c, CreatedDate, Profit__c, Close_Date_Time__c
                FROM Hidden_Divergence_Trade__c];       
    }

}