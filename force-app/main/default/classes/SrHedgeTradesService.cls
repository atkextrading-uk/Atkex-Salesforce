public with sharing class SrHedgeTradesService {
    public static List<SR_Hedge__C> getSrHedgeTradesWithStartAndEndDate (Datetime startDate, Datetime endDate) {
        endDate = DateTime.newInstanceGmt(endDate.year(), endDate.month(), endDate.day(), 23, 59, 59);
        
        System.debug(String.valueOf(startDate) + String.valueOf(endDate));
        
        List<SR_Hedge__c> listTrades = [Select id, Side__c, Profit_Percentage__c, Open_Screenshot__c,
                                        Open_Date_Time__c, Oanda_Trade_ID__c, Currency__c, Open_Comments__c,
                                        Closing_Comments__c, Close_Screenshot__c, Balance_On_Close__c, name,
                                        Final_Profit__c, Close_Date_Time__c, Outcome__c, OandaAccIdPlusTradeId__c, Second_SS__c
            FROM sr_hedge__c
            WHERE Close_Date_Time__c >= :startDate AND Close_Date_Time__c <= :endDate];

        return listTrades;

    }

    public static void deleteSrHedgeTrades(List<SR_Hedge__c> tradesToDelete) {
        try {
            System.debug('DELETE ' + tradesToDelete);

            //delete tradesToDelete;
        } catch (Exception ex) {
            System.debug('Error deleting trades');
        }
    }
}