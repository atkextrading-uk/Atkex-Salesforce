public with sharing class MonthlyTransactionService {
    public static Monthly_Transaction__C getMonthlyTransaction(Id recordId) {
        Monthly_Transaction__c mt = [Select Id, Start_Date__c, End_Date__c FROM Monthly_Transaction__c WHERE Id = :recordId];

        return mt;
    } 
}