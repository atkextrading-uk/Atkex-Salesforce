public with sharing class ConvertMonthlySrHedgeTradesToAwsDynamo {
    public static void convertRecordsToExternalRecords(Id recordId) {
        Monthly_Transaction__c mT = MonthlyTransactionService.getMonthlyTransaction(recordId);

        List<SR_Hedge__c> listTrades = SrHedgeTradesService.getSrHedgeTradesWithStartAndEndDate(mT.Start_Date__c, mT.End_Date__c);
        
        List<Oanda_Trade__x> tradesAws = OandaTradeService.createExternalRecordsFromSrHedge(listTrades, mT);
        
        OandaTradeService.insertTradesBatch(tradesAws);

        // Select primary links where the parent or child is equal to trade Id
        PrimaryLinkService.deletePrimaryLinks(listTrades);

        // Delete Records
        SrHedgeTradesService.deleteSrHedgeTrades(listTrades);

        //rollupMonthlyResults(mT.Id);


    }

    public static void rollupMonthlyResults(Id recordId) {

        Map<String, Object> params = new Map<String, Object>();
        params.put('recordId', recordId);

        Flow.Interview.Rollup_Monthly_Transactions rollupFlow = new Flow.Interview.Rollup_Monthly_Transactions(params);
        rollupFlow.start();
    }

}