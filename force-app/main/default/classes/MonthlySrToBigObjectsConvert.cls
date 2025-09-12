public with sharing class MonthlySrToBigObjectsConvert {

    //MonthlySrToBigObjectsConvert.convertRecordsToBigObjects('a097Q000004BFiSQAW');
    
    public static void convertRecordsToBigObjects(Id recordId) {
        // Get Monthly Transaction trade
        Monthly_Transaction__c mT = getMonthlyTransaction(recordId);

        // Get SR Trades that are within threshold
        List<SR_Hedge__c> listTrades = getSrHedgeTrades(mT.Start_Date__c, mT.End_Date__c);
        System.debug(listTrades);

        // Create new BO records
        List<Trade_Archive__b> tradesArchives = createTradeArchives(listTrades, mT);

        // Insert Records
        Boolean insertResult = insertArchives(tradesArchives);
        
        if (!insertResult) { return; }

        // Update monthly transaction
        Boolean updateResult = updateMonthlyTransaction(tradesArchives, mT);

        // Delete primary links
        // Select primary links where the parent or child is equal to trade Id
        deletePrimaryLinks(listTrades);

        // Delete Records
        deleteSrHedgeTrades(listTrades);

    }

    public static Monthly_Transaction__C getMonthlyTransaction(Id recordId) {
        Monthly_Transaction__c mt = [Select Id, Start_Date__c, End_Date__c FROM Monthly_Transaction__c WHERE Id = :recordId];

        return mt;
    } 
    
    public static List<SR_Hedge__C> getSrHedgeTrades (Datetime startDate, Datetime endDate) {
        endDate = DateTime.newInstanceGmt(endDate.year(), endDate.month(), endDate.day(), 23, 59, 59);
        
        System.debug(String.valueOf(startDate) + String.valueOf(endDate));
        
        List<SR_Hedge__c> listTrades = [Select id, Side__c, Profit_Percentage__c, Open_Screenshot__c,
                                        Open_Date_Time__c, Oanda_Trade_ID__c, Currency__c, Open_Comments__c,
                                        Closing_Comments__c, Close_Screenshot__c, Balance_On_Close__c, name,
                                        Final_Profit__c, Close_Date_Time__c, Outcome__c
            FROM sr_hedge__c
            WHERE Close_Date_Time__c >= :startDate AND Close_Date_Time__c <= :endDate];

        return listTrades;

    }

    public static List<Trade_Archive__b> createTradeArchives(List<SR_Hedge__c> listOfTrades, Monthly_Transaction__c mT) {
        List<Trade_Archive__b> listOfArchives = new List<Trade_Archive__b>();

        for (SR_Hedge__c trade : listOfTrades) {
            Trade_Archive__b archive = new Trade_Archive__b();
            archive.Balance_On_Close__c = trade.Balance_On_Close__c;
            archive.Close_Date_Time__c = trade.Close_Date_Time__c;
            archive.Close_URL__c = trade.Close_Screenshot__c;
            archive.Currency__c = trade.Currency__c;
            archive.Monthly_Transaction__c = mT.Id;
            archive.Name__c = trade.Name;
            archive.Oanda_ID__c = String.valueOf(trade.Oanda_Trade_ID__c);
            archive.Open_and_Close_Comments__c = 'Open : ' + trade.Open_Comments__c + ' | Close : ' + trade.Closing_Comments__c;
            archive.Open_Date_Time__c = trade.Open_Date_Time__c;
            archive.Open_URL__c = trade.Open_Screenshot__c;
            archive.Profit__c = trade.Final_Profit__c;
            archive.Profit_Percentage__c = trade.Profit_Percentage__c;
            archive.Side__c = trade.Side__c;
            archive.Outcome__c = trade.Outcome__c;

            listOfArchives.add(archive);
        }

        return listOfArchives;
    }

    public static Boolean insertArchives(List<Trade_Archive__b> listOfArchives) {
        if (!listOfArchives.isEmpty()) {
            try {
                database.insertImmediate(listOfArchives);
                System.debug(listOfArchives);
                System.debug(listOfArchives.size());
                return true;
            } catch (Exception ex) {
                return false;
            }
        }
        return false;
    }

    public static Boolean updateMonthlyTransaction(List<Trade_Archive__b> listArchives, Monthly_Transaction__c mT) {
        Decimal totalProfit = 0;
        //Get closing balance
        Decimal closingBalance = 0;
        Datetime latestCloseDate = Datetime.newInstance(2000, 01, 01);
        Integer numberOfTrades = 0;

        for (Trade_Archive__b trade : listArchives) {
            Datetime tradeCloseDate = trade.Close_Date_Time__c;
            numberOfTrades ++;
        
            if (tradeCloseDate != null && tradeCloseDate > latestCloseDate) {
                latestCloseDate = tradeCloseDate;
                closingBalance = trade.Balance_On_Close__c;
            }

            system.debug(trade.Profit__c);
            totalProfit += trade.Profit__c;

        }

        mt.Number_Of_Trades__c = numberOfTrades;
        mt.Balance_On_Close__c = closingBalance;
        mt.Profit__c = totalProfit;

        try {
            update mT;
        } catch (Exception ex) {
            System.debug('Error updating monthly transaction');
        }

        return true;
    }

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

                delete primaryLinksToDelete;
            } catch (Exception ex) {
                System.debug('Error deleting links');
            }
        }

    }

    public static void deleteSrHedgeTrades(List<SR_Hedge__c> tradesToDelete) {
        try {
            System.debug('DELETE ' + tradesToDelete);

            delete tradesToDelete;
        } catch (Exception ex) {
            System.debug('Error deleting trades');
        }
    }
}