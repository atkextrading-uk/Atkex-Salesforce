public with sharing class OandaUtility {
    public OandaUtility() {

    }

    public static List<SR_Hedge__c> tradesNew  =new List<SR_Hedge__c>();
    public static List<SR_Hedge__c> importedTrades = new List<SR_Hedge__c>();
    public static List<SR_Hedge__c> stopLossTrades = new List<SR_Hedge__c>();
    public static List<SR_Hedge__c> takeProfitTrades = new List<SR_Hedge__c>();

    private static String oandaAccountId; 
    private static Id accountId;
    private static String oandaAccIdRemoved;

    public static Integer lastTransactionId;
    public static Integer lastTransactionIdToUpdate;

    public static void updateTransation(RESTResponse.cls_transactions tr) {
        List<SR_Hedge__c> trades = new List<SR_Hedge__c>();
        Map<String, Id> currencyIdMap = new Map<String, Id>();

        oandaAccountId = '001-004-6038873-001';
        accountId = '0017Q00001AvONhQAN';
        
        Account tradingAcc = [SELECT Id, Oanda_Latest_Ticket_Number__c, OandaAccIdRemoved__c
            FROM Account 
            WHERE Id = :accountId];
        
        oandaAccIdRemoved = tradingAcc.OandaAccIdRemoved__c;
        lastTransactionId = Integer.valueOf(tradingAcc.Oanda_Latest_Ticket_Number__c);

        for(Currency__c c : [SELECT Id, Name
            FROM Currency__c]) {
            currencyIdMap.put(c.Name, c.Id);
        }
        lastTransactionId = tr.Id;
        System.debug('TEST ' + lastTransactionId + ' TYPE ' + tr.type);
        if (tr.type.equals('ORDER_FILL')) {
            
            switch on tr.reason {
                when 'MARKET_ORDER', 'LIMIT_ORDER', 'STOP_ORDER' {
                    Decimal unitsComparison = tr.units;
                    String side;
                    if (unitsComparison < 0) {
                        side = 'Sell';
                    } else {
                        side = 'Buy';
                    }
                    
                    String dateString = tr.transactionTime;
                    String trimmedDateString = dateString.substring(0, dateString.indexOf('.') + 4);

                    List<String> dateTimeParts = trimmedDateString.split('[-T:.]');
                    Integer year = Integer.valueOf(dateTimeParts[0]);
                    Integer month = Integer.valueOf(dateTimeParts[1]);
                    Integer day = Integer.valueOf(dateTimeParts[2]);
                    Integer hour = Integer.valueOf(dateTimeParts[3]);
                    Integer minute = Integer.valueOf(dateTimeParts[4]);
                    Integer second = Integer.valueOf(dateTimeParts[5]);
                    Datetime dt = Datetime.newInstanceGmt(year, month, day, hour, minute, second);
                    
                    String accPlusTrade = oandaAccIdRemoved + '' + tr.id;
                    Decimal intValue = Decimal.valueOf(accPlusTrade);

                    SR_Hedge__c trade = new SR_Hedge__c(
                        Currency__c = currencyIdMap.get((tr.instrument).replace('_','/')),
                        Side__c = side,
                        Oanda_Trade_ID__c = tr.id,
                        Trading_Account__c = accountId,
                        Open_Date_Time__c = dt,
                        X1st_Trade_Units__c = Decimal.valueOf(String.valueOf(tr.units).replace('-','')), 
                        X1st_Trade_Open_Price__c = tr.price,
                        Open_Comments__c = 'API',
                        Open_Screenshot__c = 'API',
                        OandaAccIdPlusTradeId__c = intValue
                    );
                    if (tr.accountId.equals(oandaAccountId)) {
                        tradesNew.add(trade);
                    }

                    /*System.debug('Cur ' + currencyIdMap.get((tr.instrument).replace('_','/')) 
                        + ' side ' + side + ' tId ' + tr.id + ' acc ' + '0017Q00000qPb8tQAC ' +
                        'open ' + dt + ' units ' + Decimal.valueOf(String.valueOf(tr.units).replace('-','')) +
                        ' price ' + tr.price);*/
                }
                
                when 'MARKET_ORDER_TRADE_CLOSE' {
                    String dateString = tr.transactionTime;
                    String trimmedDateString = dateString.substring(0, dateString.indexOf('.') + 4);

                    List<String> dateTimeParts = trimmedDateString.split('[-T:.]');
                    Integer year = Integer.valueOf(dateTimeParts[0]);
                    Integer month = Integer.valueOf(dateTimeParts[1]);
                    Integer day = Integer.valueOf(dateTimeParts[2]);
                    Integer hour = Integer.valueOf(dateTimeParts[3]);
                    Integer minute = Integer.valueOf(dateTimeParts[4]);
                    Integer second = Integer.valueOf(dateTimeParts[5]);
                    Datetime dt = Datetime.newInstanceGmt(year, month, day, hour, minute, second);
                    
                    String accPlusTrade = oandaAccIdRemoved + '' + tr.tradesClosed[0].tradeID;
                    Decimal intValue = Decimal.valueOf(accPlusTrade);
                    
                    SR_Hedge__c trade = new SR_Hedge__c(
                        Oanda_Trade_ID__c = tr.tradesClosed[0].tradeID,
                        Close_Date_Time__c = dt,
                        X1st_Trade_Profit__c = tr.pl,
                        X1st_Trade_Close_Price__c = tr.price,
                        Balance_On_Close__c = tr.accountBalance,
                        Closing_Comments__c = 'API',
                        Close_Screenshot__c = 'API',
                        OandaAccIdPlusTradeId__c = intValue,
                        Outcome__c = 'Closed'
                    );

                    if (tr.accountId.equals(oandaAccountId)) {
                        importedTrades.add(trade);
                    }
                }
                /*when 'STOP_ORDER' {
                    system.debug('SL Hit details ' + tr.instrument + '|Date : ' + tr.transactionTime + '| Bal ' + tr.accountBalance + '| Price ' + tr.price + '| PL' + tr.pl);
                    
                }*/
                when 'TAKE_PROFIT_ORDER', 'STOP_LOSS_ORDER', 'TRAILING_STOP_LOSS_ORDER' {
                    String dateString = tr.transactionTime;
                    String trimmedDateString = dateString.substring(0, dateString.indexOf('.') + 4);

                    

                    List<String> dateTimeParts = trimmedDateString.split('[-T:.]');
                    Integer year = Integer.valueOf(dateTimeParts[0]);
                    Integer month = Integer.valueOf(dateTimeParts[1]);
                    Integer day = Integer.valueOf(dateTimeParts[2]);
                    Integer hour = Integer.valueOf(dateTimeParts[3]);
                    Integer minute = Integer.valueOf(dateTimeParts[4]);
                    Integer second = Integer.valueOf(dateTimeParts[5]);
                    Datetime dt = Datetime.newInstanceGmt(year, month, day, hour, minute, second);
                    
                    String accPlusTrade = oandaAccIdRemoved + '' + tr.tradesClosed[0].tradeID;
                    Decimal intValue = Decimal.valueOf(accPlusTrade);
                    
                    SR_Hedge__c trade = new SR_Hedge__c(
                        Oanda_Trade_ID__c = tr.tradesClosed[0].tradeID,
                        Close_Date_Time__c = dt,
                        X1st_Trade_Profit__c = tr.pl,
                        X1st_Trade_Close_Price__c = tr.price,
                        Balance_On_Close__c = tr.accountBalance,
                        Closing_Comments__c = 'API',
                        Close_Screenshot__c = 'API',
                        OandaAccIdPlusTradeId__c = intValue
                    );

                    if (tr.reason.equals('STOP_LOSS_ORDER')) {
                        trade.Outcome__c = 'SL Hit';
                    } else if (tr.reason.equals('TAKE_PROFIT_ORDER')) {
                        trade.Outcome__c = 'TP Hit';
                    }

                    if (tr.accountId.equals(oandaAccountId)) {
                        importedTrades.add(trade);
                    }
                }
                
               }
        } else if (tr.type.equals('MARKET_ORDER') && tr.reason.equals('TRADE_CLOSE')) {
            
               system.debug('market order trade closes');
            
        } else if (tr.type.equals('TAKE_PROFIT_ORDER')) {
            System.debug('TAKEPROFIT');
            //switch on tr.reason {
                //when 'ON_FILL' {
                    String accPlusTrade = oandaAccIdRemoved + '' + tr.tradeID;
                    Decimal intValue = Decimal.valueOf(accPlusTrade);
                    
                    SR_Hedge__c trade = new SR_Hedge__c(
                        Oanda_Trade_ID__c = tr.tradeID,
                        Take_Profit_Price__c = tr.price,
                        OandaAccIdPlusTradeId__c = intValue
                    );

                    if (tr.accountId.equals(oandaAccountId)) {
                        takeProfitTrades.add(trade);
                    }

                    
                //}
           // }

        } else if (tr.type.equals('STOP_LOSS_ORDER')) {
            System.debug('SL');
            //switch on tr.reason {
                //when 'ON_FILL' {
                    String accPlusTrade = oandaAccIdRemoved + '' + tr.tradeID;
                    Decimal intValue = Decimal.valueOf(accPlusTrade);
                    System.debug('FILL ' + intValue);
                    
                    SR_Hedge__c trade = new SR_Hedge__c(
                        Oanda_Trade_ID__c = tr.tradeID,
                        Stop_Loss_Price__c = tr.price,
                        OandaAccIdPlusTradeId__c = intValue
                    );
                    if (tr.accountId.equals(oandaAccountId)) {
                        stopLossTrades.add(trade);
                    }
                //}
            //}
        }
        upsert trades OandaAccIdPlusTradeId__c;

        Account tradingAcc2 = [SELECT Id, Oanda_Latest_Ticket_Number__c
            FROM Account 
            WHERE Id = :accountId];
        
        //Get list of all oanda ID from new trades

        System.debug('Trades to add' + tradesNew);
        
        if (!tradesNew.isEmpty()) {
			
            upsert tradesNew OandaAccIdPlusTradeId__c;
        }

        System.debug('Trades to update' + importedTrades);
        if (!importedTrades.isEmpty()) {

            upsert importedTrades OandaAccIdPlusTradeId__c;
        }

        System.debug('Stop loss to update' + stopLossTrades);
        if (!stopLossTrades.isEmpty()) {

            //upsert stopLossTrades OandaAccIdPlusTradeId__c;
        }

        System.debug('Take profit to update' + takeProfitTrades);
        if (!takeProfitTrades.isEmpty()) {

            //upsert takeProfitTrades OandaAccIdPlusTradeId__c;
        }

        
        if (tradingAcc2.Oanda_Latest_Ticket_Number__c < lastTransactionIdToUpdate) {
            tradingAcc2.Oanda_Latest_Ticket_Number__c = lastTransactionIdToUpdate;
            update tradingAcc2;
        }
    }
}