public class BatchUpdateTransactions implements Database.Batchable<RESTResponse.cls_transactions>, Database.Stateful, Database.AllowsCallouts {
    public Map<String, Id> currencyIdMap = new Map<String, Id>();
    public List<SR_Hedge__c> tradesNew  =new List<SR_Hedge__c>();
    public List<SR_Hedge__c> importedTrades = new List<SR_Hedge__c>();
    public List<SR_Hedge__c> reducedTrades = new List<SR_Hedge__c>();
    public List<SR_Hedge__c> stopLossTrades = new List<SR_Hedge__c>();
    public List<SR_Hedge__c> takeProfitTrades = new List<SR_Hedge__c>();
    public Map<String, List<Partial_Close__c>> tradeCloses = new Map<String, List<Partial_Close__c>>(); 
    public Map<String, SR_Hedge__c> tradesToUpsert = new Map<String, SR_Hedge__c>();

    private String oandaAccountId; 
    private Id accountId;
    private String oandaAccIdRemoved;


    public String baseURL;
    public String apiKey;

    public Integer lastTransactionId;
    public Integer lastTransactionIdToUpdate;

    public List<RESTResponse.cls_transactions> transactions = new List<RESTResponse.cls_transactions>();

    public BatchUpdateTransactions(/*String endpoint, String apiKey,*/ Integer lastTrId, String oandaAccId, Id accId, List<RESTResponse.cls_transactions> trs) {
        System.debug('BACTH CONSTRUCTOR');

        this.oandaAccountId = oandaAccId;
        this.accountId = accId;
        
        Account tradingAcc = [SELECT Id, Oanda_Latest_Ticket_Number__c, OandaAccIdRemoved__c
            FROM Account 
            WHERE Id = :accountId];
        
        this.oandaAccIdRemoved = tradingAcc.OandaAccIdRemoved__c;
        lastTransactionId = lastTrId;

		transactions = trs;

        for(Currency__c c : [SELECT Id, Name
            FROM Currency__c]) {
            currencyIdMap.put(c.Name, c.Id);
        }
    }


    public List<RESTResponse.cls_transactions> start(Database.BatchableContext BC) {
        return transactions;
    }
        
    public void execute(Database.BatchableContext context, List<RESTResponse.cls_transactions> scope) {
        System.debug('BATCH:---- Execute');

        for (RESTResponse.cls_transactions tr : scope) {
            lastTransactionIdToUpdate = tr.Id;
            if (!tr.accountID.equals(oandaAccountId)) {
                continue;
            }
            if (tr.id < lastTransactionId) {
                continue;
            } else {
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
                                X1st_Trade_Units__c = Math.abs(tr.units), 
                                X1st_Trade_Open_Price__c = tr.price,
                                Open_Comments__c = 'API',
                                Open_Screenshot__c = 'API',
                                OandaAccIdPlusTradeId__c = intValue
                            );
                            if (tr.accountId.equals(oandaAccountId)) {
                                tradesNew.add(trade);
                                if(tradesToUpsert.get(intValue.toString()) == null) {
                                    tradesToUpsert.put(intValue.toString(), trade);
                                }
                            }

                            /*System.debug('Cur ' + currencyIdMap.get((tr.instrument).replace('_','/')) 
                                + ' side ' + side + ' tId ' + tr.id + ' acc ' + '0017Q00000qPb8tQAC ' +
                                'open ' + dt + ' units ' + Decimal.valueOf(String.valueOf(tr.units).replace('-','')) +
                                ' price ' + tr.price);*/
                        }
                        
                        when 'MARKET_ORDER_TRADE_CLOSE' {

                            // Create new parital record

                            

                            System.debug(tr.toString());
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
                            
                            //System.debug(tr.tradeReduced);
                            
                            

                            
                            SR_Hedge__c trade = new SR_Hedge__c();
                            
                            if (tr.tradeReduced != null) {
                                String accPlusTrade = oandaAccIdRemoved + '' + tr.tradeReduced.tradeID;
                            	Decimal intValue = Decimal.valueOf(accPlusTrade);
                                
                                /*trade = new SR_Hedge__c(
                                Oanda_Trade_ID__c = tr.tradeReduced.tradeID,
                                X2nd_Trade_Units__c = tr.tradeReduced.units,
                                X2nd_Trade_Profit__c = tr.tradeReduced.realizedPL,
                                X2nd_Trade_Close_Price__c = tr.tradeReduced.price,
                                OandaAccIdPlusTradeId__c = intValue);*/
                                
                                if (tradesToUpsert.get(intValue.toString()) == null) {
                                    tradesToUpsert.put(intValue.toString(), new SR_Hedge__c(
                                        OandaAccIdPlusTradeId__c = intValue
                                    ));
                                }
                                tradesToUpsert.get(intValue.toString()).Close_Date_Time__c = dt;
                                tradesToUpsert.get(intValue.toString()).Balance_On_Close__c = tr.accountBalance;
                                tradesToUpsert.get(intValue.toString()).Closing_Comments__c = 'API';
                                tradesToUpsert.get(intValue.toString()).Close_Screenshot__c = 'API';

                                Partial_Close__c pClose = new Partial_Close__c();
                                pClose.Close_Date_Time__c = dt;
                                pClose.Close_Price__c = tr.tradeReduced.price;
                                pClose.Close_Profit__c = tr.tradeReduced.realizedPL;
                                pClose.Close_Screenshot__c = 'API';
                                pClose.Closing_Comments__c = 'API';
                                pClose.Units_Closed__c = tr.tradeReduced.units;
                                //pClose.SR_Hedge__c = ; // TO FILL LATER
                                if (tradeCloses.get(intValue.toString()) == null) {
                                    tradeCloses.put(intValue.toString(), new List<Partial_Close__c>());
                                }
                                tradeCloses.get(intValue.toString()).add(pClose);
                                
                                /*if (tr.accountId.equals(oandaAccountId)) {
                                	reducedTrades.add(trade);
                            	}*/
                                continue;
                                
                            }
                            
                            if (tr.tradesClosed[0] != null) {
                                String accPlusTrade = oandaAccIdRemoved + '' + tr.tradesClosed[0].tradeID;
                                Decimal intValue = Decimal.valueOf(accPlusTrade);
                                
                                /*trade = new SR_Hedge__c(
                                    Oanda_Trade_ID__c = tr.tradesClosed[0].tradeID,
                                    Close_Date_Time__c = dt,
                                    X1st_Trade_Profit__c = tr.pl,
                                    X1st_Trade_Close_Price__c = tr.price,
                                    Balance_On_Close__c = tr.accountBalance,
                                    Closing_Comments__c = 'API',
                                    Close_Screenshot__c = 'API',
                                    OandaAccIdPlusTradeId__c = intValue,
                                    Outcome__c = 'Closed'
                                );*/
                                if (tradesToUpsert.get(intValue.toString()) == null) {
                                    tradesToUpsert.put(intValue.toString(), new SR_Hedge__c(
                                        OandaAccIdPlusTradeId__c = intValue
                                    ));
                                }
                                tradesToUpsert.get(intValue.toString()).Close_Date_Time__c = dt;
                                tradesToUpsert.get(intValue.toString()).Balance_On_Close__c = tr.accountBalance;
                                tradesToUpsert.get(intValue.toString()).Closing_Comments__c = 'API';
                                tradesToUpsert.get(intValue.toString()).Close_Screenshot__c = 'API';

                                Partial_Close__c pClose = new Partial_Close__c();
                                pClose.Close_Date_Time__c = dt;
                                pClose.Close_Price__c = tr.price;
                                pClose.Close_Profit__c = tr.pl;
                                pClose.Close_Screenshot__c = 'API';
                                pClose.Closing_Comments__c = 'API';
                                pClose.Units_Closed__c = Math.abs(tr.units);
                                pClose.Balance_On_Close__c = tr.accountBalance;
                                //pClose.SR_Hedge__c = ; // TO FILL LATER
                                if (tradeCloses.get(intValue.toString()) == null) {
                                    tradeCloses.put(intValue.toString(), new List<Partial_Close__c>());
                                }
                                tradeCloses.get(intValue.toString()).add(pClose);
                            }

                            /*if (tr.accountId.equals(oandaAccountId)) {
                                importedTrades.add(trade);
                            }*/
                            continue;
                        }
                        /*when 'STOP_ORDER' {
                            system.debug('SL Hit details ' + tr.instrument + '|Date : ' + tr.transactionTime + '| Bal ' + tr.accountBalance + '| Price ' + tr.price + '| PL' + tr.pl);
                            
                        }*/
                        when 'TAKE_PROFIT_ORDER', 'STOP_LOSS_ORDER', 'TRAILING_STOP_LOSS_ORDER' {
                            // Update to creating partial closes
                            /**
                             * Add new paritla close to map of trade id
                             * If finish get a key map of all partial trades
                             * For each partial trade, add a new trade
                             */
                            /*if(tradesToUpsert.get(intValue) != null) {
                                tradesToUpsert.put(intValue, trade);
                            }*/
                            String accPlusTrade = oandaAccIdRemoved + '' + tr.tradesClosed[0].tradeID;
                            Decimal intValue = Decimal.valueOf(accPlusTrade);
                            
                            //if (tradesToUpsert.get(intValue.toString()) == null) {}
                            SR_Hedge__c tradeToUpdate = tradesToUpsert.get(intValue.toString());

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
                            
                            
                            
                            /*SR_Hedge__c trade = new SR_Hedge__c(
                                Oanda_Trade_ID__c = tr.tradesClosed[0].tradeID,
                                Close_Date_Time__c = dt,
                                X1st_Trade_Profit__c = tr.pl,
                                X1st_Trade_Close_Price__c = tr.price,
                                Balance_On_Close__c = tr.accountBalance,
                                Closing_Comments__c = 'API',
                                Close_Screenshot__c = 'API',
                                OandaAccIdPlusTradeId__c = intValue
                            );*/

                            //Check if the value is null, add new trade
                            if (tradesToUpsert.get(intValue.toString()) == null) {
                                tradesToUpsert.put(intValue.toString(), new SR_Hedge__c(
                                    OandaAccIdPlusTradeId__c = intValue
                                ));
                            }
                            tradesToUpsert.get(intValue.toString()).Close_Date_Time__c = dt;
                            tradesToUpsert.get(intValue.toString()).Balance_On_Close__c = tr.accountBalance;
                            tradesToUpsert.get(intValue.toString()).Closing_Comments__c = 'API';
                            tradesToUpsert.get(intValue.toString()).Close_Screenshot__c = 'API';

                            Partial_Close__c pClose = new Partial_Close__c();
                            pClose.Close_Date_Time__c = dt;
                            pClose.Close_Price__c = tr.price;
                            pClose.Close_Profit__c = tr.pl;
                            pClose.Close_Screenshot__c = 'API';
                            pClose.Closing_Comments__c = 'API';
                            pClose.Units_Closed__c = Math.abs(tr.units);
                            pClose.Balance_On_Close__c = tr.accountBalance;
                            //pClose.SR_Hedge__c = ; // TO FILL LATER
                            if (tradeCloses.get(intValue.toString()) == null) {
                                tradeCloses.put(intValue.toString(), new List<Partial_Close__c>());
                            }
                            tradeCloses.get(intValue.toString()).add(pClose);

                            if (tr.reason.equals('STOP_LOSS_ORDER')) {
                                tradesToUpsert.get(intValue.toString()).Outcome__c = 'SL Hit';
                            } else if (tr.reason.equals('TAKE_PROFIT_ORDER')) {
                                tradesToUpsert.get(intValue.toString()).Outcome__c = 'TP Hit';
                            }

                            /*if (tr.accountId.equals(oandaAccountId)) {
                                importedTrades.add(trade);
                            }*/
                        }
                        
                       }
                } else if (tr.type.equals('MARKET_ORDER') && tr.reason.equals('TRADE_CLOSE')) {
                    
                       system.debug('market order trade closes');
                    
                } else if (tr.type.equals('TAKE_PROFIT_ORDER')) {
                    //switch on tr.reason {
                        //when 'ON_FILL' {
                            String accPlusTrade = oandaAccIdRemoved + '' + tr.tradeID;
                            Decimal intValue = Decimal.valueOf(accPlusTrade);

                            if (tradesToUpsert.get(intValue.toString()) == null) {
                                tradesToUpsert.put(intValue.toString(), new SR_Hedge__c(
                                    OandaAccIdPlusTradeId__c = intValue
                                ));
                            }
                            tradesToUpsert.get(intValue.toString()).Take_Profit_Price__c = tr.price;
                            
                            /*SR_Hedge__c trade = new SR_Hedge__c(
                                Oanda_Trade_ID__c = tr.tradeID,
                                Take_Profit_Price__c = tr.price,
                                OandaAccIdPlusTradeId__c = intValue
                            );

                            if (tr.accountId.equals(oandaAccountId)) {
                                takeProfitTrades.add(trade);
                            }*/

                            
                        //}
                    //}

                } else if (tr.type.equals('STOP_LOSS_ORDER')) {
                    //switch on tr.reason {
                        //when 'ON_FILL' {
                            System.debug('SL TRADE');
                            String accPlusTrade = oandaAccIdRemoved + '' + tr.tradeID;
                            Decimal intValue = Decimal.valueOf(accPlusTrade);

                            //tradesToUpsert.get(intValue.toString()).Stop_Loss_Price__c = tr.price;
                            if (tradesToUpsert.get(intValue.toString()) == null) {
                                tradesToUpsert.put(intValue.toString(), new SR_Hedge__c(
                                    OandaAccIdPlusTradeId__c = intValue
                                ));
                            }
                            tradesToUpsert.get(intValue.toString()).Stop_Loss_Price__c = tr.price;

                            /*SR_Hedge__c trade = new SR_Hedge__c(
                                Oanda_Trade_ID__c = tr.tradeID,
                                Stop_Loss_Price__c = tr.price,
                                OandaAccIdPlusTradeId__c = intValue
                            );
                            if (tr.accountId.equals(oandaAccountId)) {
                                stopLossTrades.add(trade);
                            }*/
                        //}
                    //}
                }

                System.debug('Trans: ' + tr.id);
            }
        }
    }
        
    public void finish(Database.BatchableContext context) {
        System.debug('BACTH COMPLETE:---- ');
        
        Account tradingAcc = [SELECT Id, Oanda_Latest_Ticket_Number__c
            FROM Account 
            WHERE Id = :accountId];
        
        //Get list of all oanda ID from new trades

        /*System.debug('Trades to add' + tradesNew);
        
        if (!tradesNew.isEmpty()) {
			
            upsert tradesNew OandaAccIdPlusTradeId__c;
        }

        System.debug('Trades to update' + importedTrades);
        if (!importedTrades.isEmpty()) {

            upsert importedTrades OandaAccIdPlusTradeId__c;
        }
            
        System.debug('Trades to reduce' + reducedTrades);
        if (!reducedTrades.isEmpty()) {

            upsert reducedTrades OandaAccIdPlusTradeId__c;
        }

        System.debug('Stop loss to update' + stopLossTrades);
        if (!stopLossTrades.isEmpty()) {

            upsert stopLossTrades OandaAccIdPlusTradeId__c;
        }

        System.debug('Take profit to update' + takeProfitTrades);
        if (!takeProfitTrades.isEmpty()) {

            upsert takeProfitTrades OandaAccIdPlusTradeId__c;
        }*/

        System.debug('Trades to upsert' + tradesToUpsert);
        //Get a list of all trades to update
        List<SR_Hedge__c> allSRHedges = new List<SR_Hedge__c>();
        Set<Decimal> tradeIds = new Set<Decimal>();

        for (SR_Hedge__c srHedge : tradesToUpsert.values()) {
            allSRHedges.add(srHedge);
            tradeIds.add(srHedge.OandaAccIdPlusTradeId__c);
        }

        if (!allSRHedges.isEmpty()) {
            upsert allSRHedges OandaAccIdPlusTradeId__c;
        }

        //public Map<String, List<Partial_Close__c>> tradeCloses = new Map<String, List<Partial_Close__c>>(); 
        Map<String, String> srHedgeAccIdMap = new Map<String, String>();

        for (SR_Hedge__c srHedge : [SELECT Id, OandaAccIdPlusTradeId__c FROM SR_Hedge__c WHERE OandaAccIdPlusTradeId__c IN :tradeIds]) {
            srHedgeAccIdMap.put(srHedge.OandaAccIdPlusTradeId__c.toString(), srHedge.Id);
        }

        List<Partial_Close__c> allPartialCloses = new List<Partial_Close__c>();
        System.debug('MAP ' + srHedgeAccIdMap);

        for (String partialClosesKey : tradeCloses.keySet()) {
            for (Partial_Close__c partialClose : tradeCloses.get(partialClosesKey.toString())) {
                //system.debug(partialClosesKey.toString()+ 'HERE ' + partialClose + ' | ' + srHedgeAccIdMap.get(srHedgeAccIdMap.get(partialClosesKey.toString())));
                partialClose.SR_Hedge__c = srHedgeAccIdMap.get(partialClosesKey.toString());
                allPartialCloses.add(partialClose);
            }
        }

        System.debug('Closes to insert' + allPartialCloses);

        if (!allPartialCloses.isEmpty()) {
            insert allPartialCloses;
        }

        

        
        if (tradingAcc.Oanda_Latest_Ticket_Number__c < lastTransactionIdToUpdate) {
            tradingAcc.Oanda_Latest_Ticket_Number__c = lastTransactionIdToUpdate;
            update tradingAcc;
        }
        
    }

    
}