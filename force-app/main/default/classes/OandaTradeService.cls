public without sharing class OandaTradeService {
    @AuraEnabled(Cacheable=true)
    public static Oanda_Trade__x getOandaTradeImageUrls(Id recordId) {
        return [
            SELECT Open_URL__c, Close_URL__c, Second_Screenshot__c
            FROM Oanda_Trade__x
            WHERE Id = :recordId 
            LIMIT 1
        ];
    }

    public static List<Oanda_Trade__x> createExternalRecordsFromSrHedge(List<SR_Hedge__c> listOfTrades, Monthly_Transaction__c mT) {
        List<Oanda_Trade__x> listOfArchives = new List<Oanda_Trade__x>();

        for (SR_Hedge__c trade : listOfTrades) {
            Oanda_Trade__x archive = new Oanda_Trade__x();
            archive.Balance_On_Close__c = trade.Balance_On_Close__c;
            archive.Close_Comments__c = trade.Closing_Comments__c;
            archive.Close_Date_Time__c = trade.Close_Date_Time__c;
            archive.Index__c = trade.OandaAccIdPlusTradeId__c;
            archive.Close_URL__c = trade.Close_Screenshot__c;
            archive.Currency__c = trade.Currency__c;
            archive.Monthly_Transaction__c = mT.Id;
            archive.Name__c = trade.Name;
            archive.Oanda_ID__c = trade.Oanda_Trade_ID__c;
            archive.Open_Comments__c =  trade.Open_Comments__c;
            archive.Open_Date_Time__c = trade.Open_Date_Time__c;
            archive.Open_URL__c = trade.Open_Screenshot__c;
            archive.Profit_Loss__c = trade.Final_Profit__c;
            archive.Profit_Percentage__c = trade.Profit_Percentage__c;
            archive.Side__c = trade.Side__c;
            archive.Outcome__c = trade.Outcome__c;
            archive.Second_Screenshot__c = trade.Second_SS__c;

            listOfArchives.add(archive);
        }

        return listOfArchives;
    }

    public static void insertTradesBatch(List<Oanda_Trade__x> listOfArchives) {
        if (!listOfArchives.isEmpty()) {
            BatchInsertDynamo batchInsert = new BatchInsertDynamo(listOfArchives);

            Database.executeBatch(batchInsert, 10);
        }
    }
}