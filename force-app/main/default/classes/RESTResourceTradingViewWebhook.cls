@RestResource(urlMapping='/rr-tradingview/*')
global class RESTResourceTradingViewWebhook {
    @HttpPost
    global static void doPost() {
        System.RestRequest request = RestContext.request;
        String requestBody = request.requestBody.toString();

        String requestURI = request.requestURI;
        System.debug('Request URI: ' + requestURI);

        // Assuming your URL mapping is /rr-tradingview/*
        String[] uriParts = requestURI.split('/');
        String action = uriParts.size() > 2 ? uriParts[2] : '';

        System.debug('TEST REQ | ' + requestBody + ' | ' + action);

        if (action == 'call') {
            // Handle /rr-tradingview/call
            System.debug('MAKE CALL');
            TwilioAPIHandler.makeCall();  // Uncomment and implement this method as needed
        } else if (action == 'signal') {
            // Handle /rr-tradingview/signal
            System.debug('SIGNAL');
            //Callout to make oanda trade  // Uncomment and implement this method as needed
            placeTrade(requestBody);
        }  else if (action == 'signal2') {
            // Handle /rr-tradingview/signal
            System.debug('signal2');
            //Callout to make oanda trade  // Uncomment and implement this method as needed
            placeTrade2(requestBody);
        }


        // If param is /call, make call, if not signal trade
        //

        System.RestResponse response = RestContext.response;

        

    }

    private static void placeTrade2(String strBody) {

        //RESTResponse.OandaTransactionsPage page = (RESTResponse.OandaTransactionsPage) JSON.deserialize(jsonString, RESTResponse.OandaTransactionsPage.class);     


        SignalTrade tradeSignal = (SignalTrade) JSON.deserialize(strBody, SignalTrade.class);

        HttpRequest req = new HttpRequest();
            req.setEndpoint('https://api-fxpractice.oanda.com/v3/accounts/101-004-23424312-001/orders');
            req.setHeader('Authorization', 'Bearer 1f1befaad5d67687ff7e0aa2eb10eac7-d09b57596e582795520209741fc897f8');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');

        Decimal unitsTrade;
        Decimal trailingStopLoss;

        if (tradeSignal.side == 'buy') {
            unitsTrade = 1000;//tradeSignal.contracts;
        } else {
            unitsTrade = -1000;//-tradeSignal.contracts;
        }

        String jsonBody = '{"order":{"type" : "MARKET","instrument" : "USD_JPY","units" : ' + unitsTrade +
            ',"timeInForce" : "FOK","positionFill" : "DEFAULT"}}';

        req.setBody(jsonBody);

        System.debug('REQ | ' + req + ' BODY ' + jsonBody);

        Account acc = [Select Id, Second_SS__c FROM Account Where Id  ='0017Q00000qPbARQA0'];

        System.debug('HERE ' +acc.Second_SS__c);

        if (acc.Second_SS__c == null) {
            Http http = new Http();
            HTTPResponse res = http.send(req);
    
            if (res.getStatusCode() == 201) {
                // Parse the response to get the trade ID
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                Map<String, Object> orderFillTransaction = (Map<String, Object>) responseMap.get('orderFillTransaction');
                String tradeId = (String) orderFillTransaction.get('id');
    
                acc.Second_SS__c = tradeId;
                update acc;
        
                // Schedule the closure of the trade after 60 seconds
                // String cronExp = System.now().addSeconds(60).format('s m H d M \'?\' yyyy');
                // CloseTradeAfterDelay job = new CloseTradeAfterDelay(tradeId, '101-004-23424312-002');
                // System.schedule('CloseTradeJob' + System.currentTimeMillis(), cronExp, job);
        
                // System.debug('Trade will be closed after 60 seconds, trade ID: ' + tradeId);
            } else {
                System.debug('Failed to place trade: ' + res.getBody());
            }
        } else {
            HTTPResponse res = closeTrade(acc.Second_SS__c, '101-004-23424312-001', '1f1befaad5d67687ff7e0aa2eb10eac7-d09b57596e582795520209741fc897f8');
            acc.Second_SS__c = '';
            update acc;
            
            
            return;
        }

        
    }

    private static HTTPResponse closeTrade(String tradeId, String accountId, String bearerToken) {
        
        String endpoint = 'https://api-fxpractice.oanda.com/v3/accounts/' + accountId + '/trades/' + tradeId + '/close';
    
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setHeader('Authorization', 'Bearer ' + bearerToken);
        req.setMethod('PUT');
        req.setHeader('Content-Type', 'application/json');

        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug('Close trade response: ' + res.getBody());
        return res;

    }
    
    @future(callout=true)
    private static void placeTradeFuture(String str) {
        placeTrade(str);
    }

    public static void placeTrade(String strBody) {

        //RESTResponse.OandaTransactionsPage page = (RESTResponse.OandaTransactionsPage) JSON.deserialize(jsonString, RESTResponse.OandaTransactionsPage.class);     


        SignalTrade tradeSignal = (SignalTrade) JSON.deserialize(strBody, SignalTrade.class);

        HttpRequest req = new HttpRequest();
            req.setEndpoint('https://api-fxpractice.oanda.com/v3/accounts/101-004-23424312-002/orders');
            req.setHeader('Authorization', 'Bearer 3ca1fa8d639245ae65178cdfda22708e-82f12203086ee753781867a146bde7f0');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');

        Decimal unitsTrade;
        
        // Check first trade, if it is buy, and buy, then add anotehr buy
        // If it is buy, buy and buy, add trade
        // If the first does not equal the new, then close and open another
        
        Account accFirst = [Select Id, Second_SS__c, First_Trade__c, Second_Trade__c, Third_Trade__c, Oanda_Account_Id__c FROM Account Where Id  ='0017Q00001TwBUCQA3'];
        
        String firstTradeData = accFirst.First_Trade__c;
        String secondTradeData = accFirst.Second_Trade__c;
        String thirdTradeData = accFirst.Third_Trade__c;
		
        
        // if anythign is take profit, close
        if (tradeSignal.comment == 'Take Profit Short' || tradeSignal.comment == 'Take Profit Long') {
            // Close all trades
            HTTPResponse res1;
            HTTPResponse res2;
            HTTPResponse res3;
            
            List<String> firstTradeParts = new List<String>();
            List<String> secondTradeParts = new List<String>();
            List<String> thirdTradeParts = new List<String>();
            
            if (firstTradeData != null) {
                firstTradeParts = firstTradeData.split('-');
                res1 = closeTrade(firstTradeParts[1], '101-004-23424312-002', '3ca1fa8d639245ae65178cdfda22708e-82f12203086ee753781867a146bde7f0');
            }
            
            if (secondTradeData != null) { 
                secondTradeParts = secondTradeData.split('-');
                res2 = closeTrade(secondTradeParts[1], '101-004-23424312-002', '3ca1fa8d639245ae65178cdfda22708e-82f12203086ee753781867a146bde7f0');

            }
                
            if (thirdTradeData != null) {
                thirdTradeParts = thirdTradeData.split('-');
                res3 = closeTrade(thirdTradeParts[1], '101-004-23424312-002', '3ca1fa8d639245ae65178cdfda22708e-82f12203086ee753781867a146bde7f0');

            }
            
            if (firstTradeData != null) {
                //List<String> firstTradeParts = firstTradeData.split('-');
            
                String index = accFirst.Id + '-' + accFirst.Oanda_Account_Id__c + '-' + firstTradeParts[1];
                accFirst.First_Trade__c = '';
                update accFirst;
                
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res1.getBody());
                Map<String, Object> orderFillTransaction = (Map<String, Object>) responseMap.get('orderFillTransaction');
                
                String timeStr = String.valueOf(orderFillTransaction.get('time'));
                timeStr = timeStr.substring(0, timeStr.length() - 1);
                timeStr = timeStr.substring(0, timeStr.indexOf('.'));
                timeStr = timeStr.replace('T', ' ');
    
                     
                Datetime endDateTime =  Datetime.valueOf(timeStr);
                //Datetime endDateTime = (Datetime) orderFillTransaction.get('time');
                
                Algo_Trade__c algoTrade = [SELECT Id, Trade_ID__c,
                                                  Close_Date_Time__c, Profit__c,
                                                  Profit_Percentage__c, Start_Balance__c
                                                  FROM Algo_Trade__c WHERE Unique_Id__c = :index];
                Decimal accountBalance = Decimal.valueOf(String.valueOf(orderFillTransaction.get('accountBalance')));
                Decimal profit = Decimal.valueOf(String.valueOf(orderFillTransaction.get('pl')));
                Decimal profitPercentage = (profit / algoTrade.Start_Balance__c) * 100;
                algoTrade.Close_Date_Time__c = endDateTime;
                algoTrade.Profit__c = profit;
                algoTrade.Profit_Percentage__c = profitPercentage;
                
                update algoTrade;

            }
            if (secondTradeData != null) {
            
                String index = accFirst.Id + '-' + accFirst.Oanda_Account_Id__c + '-' + secondTradeParts[1];
                accFirst.Second_Trade__c = '';
                update accFirst;
                
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res2.getBody());
                Map<String, Object> orderFillTransaction = (Map<String, Object>) responseMap.get('orderFillTransaction');
                
                String timeStr = String.valueOf(orderFillTransaction.get('time'));
                timeStr = timeStr.substring(0, timeStr.length() - 1);
                timeStr = timeStr.substring(0, timeStr.indexOf('.'));
                timeStr = timeStr.replace('T', ' ');
    
                     
                Datetime endDateTime =  Datetime.valueOf(timeStr);
                //Datetime endDateTime = (Datetime) orderFillTransaction.get('time');
                
                Algo_Trade__c algoTrade = [SELECT Id, Trade_ID__c,
                                                  Close_Date_Time__c, Profit__c,
                                                  Profit_Percentage__c, Start_Balance__c
                                                  FROM Algo_Trade__c WHERE Unique_Id__c = :index];
                Decimal accountBalance = Decimal.valueOf(String.valueOf(orderFillTransaction.get('accountBalance')));
                Decimal profit = Decimal.valueOf(String.valueOf(orderFillTransaction.get('pl')));
                Decimal profitPercentage = (profit / algoTrade.Start_Balance__c) * 100;
                algoTrade.Close_Date_Time__c = endDateTime;
                algoTrade.Profit__c = profit;
                algoTrade.Profit_Percentage__c = profitPercentage;
                
                update algoTrade;
            }
            
            if (thirdTradeData != null) {
            
                String index = accFirst.Id + '-' + accFirst.Oanda_Account_Id__c + '-' + thirdTradeParts[1];
                accFirst.Third_Trade__c = '';
                update accFirst;
                
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res3.getBody());
                Map<String, Object> orderFillTransaction = (Map<String, Object>) responseMap.get('orderFillTransaction');
                
                String timeStr = String.valueOf(orderFillTransaction.get('time'));
                timeStr = timeStr.substring(0, timeStr.length() - 1);
                timeStr = timeStr.substring(0, timeStr.indexOf('.'));
                timeStr = timeStr.replace('T', ' ');
    
                     
                Datetime endDateTime =  Datetime.valueOf(timeStr);
                //Datetime endDateTime = (Datetime) orderFillTransaction.get('time');
                
                Algo_Trade__c algoTrade = [SELECT Id, Trade_ID__c,
                                                  Close_Date_Time__c, Profit__c,
                                                  Profit_Percentage__c, Start_Balance__c
                                                  FROM Algo_Trade__c WHERE Unique_Id__c = :index];
                Decimal accountBalance = Decimal.valueOf(String.valueOf(orderFillTransaction.get('accountBalance')));
                Decimal profit = Decimal.valueOf(String.valueOf(orderFillTransaction.get('pl')));
                Decimal profitPercentage = (profit / algoTrade.Start_Balance__c) * 100;
                algoTrade.Close_Date_Time__c = endDateTime;
                algoTrade.Profit__c = profit;
                algoTrade.Profit_Percentage__c = profitPercentage;
                
                update algoTrade;
            }
            
          
            accFirst.First_Trade__c = '';
            accFirst.Second_Trade__c = '';
            accFirst.Third_Trade__c = '';
            update accFirst;
            return;
        }
        
        if (tradeSignal.side == 'buy') {
            unitsTrade = 1;
        } else {
            unitsTrade = -1;
        }
        
        Http http = new Http();

        String jsonBody = '{"order":{"type" : "MARKET","instrument" : "XAU_USD","units" : "' + unitsTrade + '","timeInForce" : "FOK","positionFill" : "DEFAULT"}}';
        
        req.setBody(jsonBody);	
        
        if (firstTradeData != null) {
            List<String> firstTradeParts = firstTradeData.split('-');
            if (firstTradeParts[0] == tradeSignal.side) {	
                
                if (secondTradeData != null) {
                    List<String> secondTradeParts = secondTradeData.split('-');
                    if (secondTradeParts[0] == tradeSignal.side) {
		                        
                        if (thirdTradeData != null) {
                            List<String> thirdTradeParts = thirdTradeData.split('-');
                            if (secondTradeParts[0] != tradeSignal.side) {
                                // Close all and place new
                                HTTPResponse res = closeTrade(firstTradeParts[1], '101-004-23424312-002', '3ca1fa8d639245ae65178cdfda22708e-82f12203086ee753781867a146bde7f0');
                                HTTPResponse res2 = closeTrade(secondTradeParts[1], '101-004-23424312-002', '3ca1fa8d639245ae65178cdfda22708e-82f12203086ee753781867a146bde7f0');

                        
                                String index = accFirst.Id + '-' + accFirst.Oanda_Account_Id__c + '-' + firstTradeParts[1];
                                String index2 = accFirst.Id + '-' + accFirst.Oanda_Account_Id__c + '-' + secondTradeParts[1];

                                accFirst.First_Trade__c = '';
                                accFirst.Second_Trade__c = '';
                                update accFirst;
                                
                                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                                Map<String, Object> orderFillTransaction = (Map<String, Object>) responseMap.get('orderFillTransaction');
                                
                                Map<String, Object> responseMap2 = (Map<String, Object>) JSON.deserializeUntyped(res2.getBody());
                                Map<String, Object> orderFillTransaction2 = (Map<String, Object>) responseMap2.get('orderFillTransaction');
                                
                                String timeStr = String.valueOf(orderFillTransaction.get('time'));
                                timeStr = timeStr.substring(0, timeStr.length() - 1);
                                timeStr = timeStr.substring(0, timeStr.indexOf('.'));
                                timeStr = timeStr.replace('T', ' ');
                    
                                String timeStr2 = String.valueOf(orderFillTransaction2.get('time'));
                                timeStr = timeStr2.substring(0, timeStr2.length() - 1);
                                timeStr = timeStr2.substring(0, timeStr2.indexOf('.'));
                                timeStr = timeStr2.replace('T', ' ');
                                     
                                Datetime endDateTime =  Datetime.valueOf(timeStr);
                                Datetime endDateTime2 =  Datetime.valueOf(timeStr2);

                                //Datetime endDateTime = (Datetime) orderFillTransaction.get('time');
                                
                                Algo_Trade__c algoTrade = [SELECT Id, Trade_ID__c,
                                                                  Close_Date_Time__c, Profit__c,
                                                                  Profit_Percentage__c, Start_Balance__c
                                                                  FROM Algo_Trade__c WHERE Unique_Id__c = :index];
                                Decimal accountBalance = Decimal.valueOf(String.valueOf(orderFillTransaction.get('accountBalance')));
               				 	Decimal profit = Decimal.valueOf(String.valueOf(orderFillTransaction.get('pl')));
                                Decimal profitPercentage = (profit / algoTrade.Start_Balance__c) * 100;
                                algoTrade.Close_Date_Time__c = endDateTime;
                                algoTrade.Profit__c = profit;
                                algoTrade.Profit_Percentage__c = profitPercentage;
                                
                                update algoTrade;
                                
                                Algo_Trade__c algoTrade2 = [SELECT Id, Trade_ID__c,
                                                                  Close_Date_Time__c, Profit__c,
                                                                  Profit_Percentage__c, Start_Balance__c
                                                                  FROM Algo_Trade__c WHERE Unique_Id__c = :index2];
                                Decimal accountBalance2 = Decimal.valueOf(String.valueOf(orderFillTransaction2.get('accountBalance')));
                                Decimal profit2 = accountBalance2 - algoTrade2.Start_Balance__c;
                                Decimal profitPercentage2 = (profit2 / algoTrade2.Start_Balance__c) * 100;
                                algoTrade2.Close_Date_Time__c = endDateTime2;
                                algoTrade2.Profit__c = profit2;
                                algoTrade2.Profit_Percentage__c = profitPercentage2;
                                
                                update algoTrade2;
                                                                
                                if (tradeSignal.comment == 'Long' || tradeSignal.comment == 'Short') { 
                                    placeTradeFuture(strBody);
                                    return;
                                }
                                
                            }
                        } else {
                            req.setBody(jsonBody);
            
                            HTTPResponse res = http.send(req);
                            
                            if (res.getStatusCode() == 201) {
                                // Parse the response to get the trade ID
                                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                                Map<String, Object> orderFillTransaction = (Map<String, Object>) responseMap.get('orderFillTransaction');
                                String tradeId = (String) orderFillTransaction.get('id');
                                Decimal accountBalance = Decimal.valueOf(String.valueOf(orderFillTransaction.get('accountBalance')));
                                String timeStr = String.valueOf(orderFillTransaction.get('time'));
                                timeStr = timeStr.substring(0, timeStr.length() - 1);
                                timeStr = timeStr.substring(0, timeStr.indexOf('.'));
                                timeStr = timeStr.replace('T', ' ');
                
                                 
                                Datetime startDateTime =  Datetime.valueOf(timeStr);
                                String index = accFirst.Id + '-' + accFirst.Oanda_Account_Id__c + '-' + tradeId;
                    
                                accFirst.Third_Trade__c = tradeSignal.side + '-' + tradeId;
                                update accFirst;
                                
                                Algo_Trade__c tradeInsert = new Algo_Trade__c();
                                tradeInsert.Trading_Account__c = accFirst.Id;
                                tradeInsert.Open_Date_Time__c = startDateTime;
                                tradeInsert.Unique_Id__c = index;
                                tradeInsert.Start_Balance__c = accountBalance;
                                tradeInsert.Trade_Id__c = tradeId;
                                
                                insert tradeInsert;
                            }
                        }
                    } else {
                        // Close 2 and re-buy
                        HTTPResponse res = closeTrade(firstTradeParts[1], '101-004-23424312-002', '3ca1fa8d639245ae65178cdfda22708e-82f12203086ee753781867a146bde7f0');
                        HTTPResponse res2 = closeTrade(secondTradeParts[1], '101-004-23424312-002', '3ca1fa8d639245ae65178cdfda22708e-82f12203086ee753781867a146bde7f0');

                
                        String index = accFirst.Id + '-' + accFirst.Oanda_Account_Id__c + '-' + firstTradeParts[1];
                        String index2 = accFirst.Id + '-' + accFirst.Oanda_Account_Id__c + '-' + secondTradeParts[1];

                        accFirst.First_Trade__c = '';
                        accFirst.Second_Trade__c = '';
                        update accFirst;
                        
                        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                        Map<String, Object> orderFillTransaction = (Map<String, Object>) responseMap.get('orderFillTransaction');
                        
                        Map<String, Object> responseMap2 = (Map<String, Object>) JSON.deserializeUntyped(res2.getBody());
                        Map<String, Object> orderFillTransaction2 = (Map<String, Object>) responseMap2.get('orderFillTransaction');
                        
                        String timeStr = String.valueOf(orderFillTransaction.get('time'));
                        timeStr = timeStr.substring(0, timeStr.length() - 1);
                        timeStr = timeStr.substring(0, timeStr.indexOf('.'));
                        timeStr = timeStr.replace('T', ' ');
            
                        String timeStr2 = String.valueOf(orderFillTransaction2.get('time'));
                        timeStr = timeStr2.substring(0, timeStr2.length() - 1);
                        timeStr = timeStr2.substring(0, timeStr2.indexOf('.'));
                        timeStr = timeStr2.replace('T', ' ');
                             
                        Datetime endDateTime =  Datetime.valueOf(timeStr);
                        Datetime endDateTime2 =  Datetime.valueOf(timeStr2);

                        //Datetime endDateTime = (Datetime) orderFillTransaction.get('time');
                        
                        Algo_Trade__c algoTrade = [SELECT Id, Trade_ID__c,
                                                          Close_Date_Time__c, Profit__c,
                                                          Profit_Percentage__c, Start_Balance__c
                                                          FROM Algo_Trade__c WHERE Unique_Id__c = :index];
                        Decimal accountBalance = Decimal.valueOf(String.valueOf(orderFillTransaction.get('accountBalance')));
                		Decimal profit = Decimal.valueOf(String.valueOf(orderFillTransaction.get('pl')));
                        Decimal profitPercentage = (profit / algoTrade.Start_Balance__c) * 100;
                        algoTrade.Close_Date_Time__c = endDateTime;
                        algoTrade.Profit__c = profit;
                        algoTrade.Profit_Percentage__c = profitPercentage;
                        
                        update algoTrade;
                        
                        Algo_Trade__c algoTrade2 = [SELECT Id, Trade_ID__c,
                                                          Close_Date_Time__c, Profit__c,
                                                          Profit_Percentage__c, Start_Balance__c
                                                          FROM Algo_Trade__c WHERE Unique_Id__c = :index2];
                        Decimal accountBalance2 = Decimal.valueOf(String.valueOf(orderFillTransaction2.get('accountBalance')));
                        Decimal profit2 = accountBalance2 - algoTrade2.Start_Balance__c;
                        Decimal profitPercentage2 = (profit2 / algoTrade2.Start_Balance__c) * 100;
                        algoTrade2.Close_Date_Time__c = endDateTime2;
                        algoTrade2.Profit__c = profit2;
                        algoTrade2.Profit_Percentage__c = profitPercentage2;
                        
                        update algoTrade2;
                                                        
                        if (tradeSignal.comment == 'Long' || tradeSignal.comment == 'Short') { 
                            placeTradeFuture(strBody);
                            return;
                        }
                    }
                        
                    	
                    
                } else {
                	// Second tarde is null
                	//List<String> secondTradeParts = secondTradeData.split('-');
                    if (firstTradeParts[0] == tradeSignal.side) {
                        req.setBody(jsonBody);
            
                        HTTPResponse res = http.send(req);
                        
                        if (res.getStatusCode() == 201) {
                            // Parse the response to get the trade ID
                            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                            Map<String, Object> orderFillTransaction = (Map<String, Object>) responseMap.get('orderFillTransaction');
                            String tradeId = (String) orderFillTransaction.get('id');
                            Decimal accountBalance = Decimal.valueOf(String.valueOf(orderFillTransaction.get('accountBalance')));
                            String timeStr = String.valueOf(orderFillTransaction.get('time'));
                            timeStr = timeStr.substring(0, timeStr.length() - 1);
                            timeStr = timeStr.substring(0, timeStr.indexOf('.'));
                            timeStr = timeStr.replace('T', ' ');
            
                             
                            Datetime startDateTime =  Datetime.valueOf(timeStr);
                            String index = accFirst.Id + '-' + accFirst.Oanda_Account_Id__c + '-' + tradeId;
                
                            accFirst.Second_Trade__c = tradeSignal.side + '-' + tradeId;
                            update accFirst;
                            
                            Algo_Trade__c tradeInsert = new Algo_Trade__c();
                            tradeInsert.Trading_Account__c = accFirst.Id;
                            tradeInsert.Open_Date_Time__c = startDateTime;
                            tradeInsert.Unique_Id__c = index;
                            tradeInsert.Start_Balance__c = accountBalance;
                            tradeInsert.Trade_Id__c = tradeId;
                            
                            insert tradeInsert;
                        }
                    } else {
                        HTTPResponse res = closeTrade(firstTradeParts[1], '101-004-23424312-002', '3ca1fa8d639245ae65178cdfda22708e-82f12203086ee753781867a146bde7f0');
                        
                        String index = accFirst.Id + '-' + accFirst.Oanda_Account_Id__c + '-' + firstTradeParts[1];
                        accFirst.First_Trade__c = '';
                        update accFirst;
                        
                        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                        Map<String, Object> orderFillTransaction = (Map<String, Object>) responseMap.get('orderFillTransaction');
                        
                        String timeStr = String.valueOf(orderFillTransaction.get('time'));
                        timeStr = timeStr.substring(0, timeStr.length() - 1);
                        timeStr = timeStr.substring(0, timeStr.indexOf('.'));
                        timeStr = timeStr.replace('T', ' ');
            
                             
                        Datetime endDateTime =  Datetime.valueOf(timeStr);
                        //Datetime endDateTime = (Datetime) orderFillTransaction.get('time');
                        
                        Algo_Trade__c algoTrade = [SELECT Id, Trade_ID__c,
                                                          Close_Date_Time__c, Profit__c,
                                                          Profit_Percentage__c, Start_Balance__c
                                                          FROM Algo_Trade__c WHERE Unique_Id__c = :index];
                        Decimal accountBalance = Decimal.valueOf(String.valueOf(orderFillTransaction.get('accountBalance')));
                		Decimal profit = Decimal.valueOf(String.valueOf(orderFillTransaction.get('pl')));
                        Decimal profitPercentage = (profit / algoTrade.Start_Balance__c) * 100;
                        algoTrade.Close_Date_Time__c = endDateTime;
                        algoTrade.Profit__c = profit;
                        algoTrade.Profit_Percentage__c = profitPercentage;
                        
                        update algoTrade;
                        
                        
                        if (tradeSignal.comment == 'Long' || tradeSignal.comment == 'Short') { 
                            placeTradeFuture(strBody);
                            return;
                        }
                    }
                	
                }
                
            } else {
                // Close all trades
                // Add a first new trade -- Checkj
                // 
                
                HTTPResponse res1;
                HTTPResponse res2;
                HTTPResponse res3;
                
                List<String> secondTradeParts = new List<String>();
                List<String> thirdTradeParts = new List<String>();
                
                if (firstTradeData != null) {
                    res1 = closeTrade(firstTradeParts[1], '101-004-23424312-002', '3ca1fa8d639245ae65178cdfda22708e-82f12203086ee753781867a146bde7f0');
                }
                
                if (secondTradeData != null) { 
                    secondTradeParts = secondTradeData.split('-');
                    res2 = closeTrade(secondTradeParts[1], '101-004-23424312-002', '3ca1fa8d639245ae65178cdfda22708e-82f12203086ee753781867a146bde7f0');

                }
                    
                if (thirdTradeData != null) {
                    thirdTradeParts = thirdTradeData.split('-');
                    res3 = closeTrade(thirdTradeParts[1], '101-004-23424312-002', '3ca1fa8d639245ae65178cdfda22708e-82f12203086ee753781867a146bde7f0');

                }
                
                if (firstTradeData != null) {
                    //List<String> firstTradeParts = firstTradeData.split('-');
                
                    String index = accFirst.Id + '-' + accFirst.Oanda_Account_Id__c + '-' + firstTradeParts[1];
                    accFirst.First_Trade__c = '';
                    update accFirst;
                    
                    Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res1.getBody());
                    Map<String, Object> orderFillTransaction = (Map<String, Object>) responseMap.get('orderFillTransaction');
                    
                    String timeStr = String.valueOf(orderFillTransaction.get('time'));
                    timeStr = timeStr.substring(0, timeStr.length() - 1);
                    timeStr = timeStr.substring(0, timeStr.indexOf('.'));
                    timeStr = timeStr.replace('T', ' ');
        
                         
                    Datetime endDateTime =  Datetime.valueOf(timeStr);
                    //Datetime endDateTime = (Datetime) orderFillTransaction.get('time');
                    
                    Algo_Trade__c algoTrade = [SELECT Id, Trade_ID__c,
                                                      Close_Date_Time__c, Profit__c,
                                                      Profit_Percentage__c, Start_Balance__c
                                                      FROM Algo_Trade__c WHERE Unique_Id__c = :index];
                    Decimal accountBalance = Decimal.valueOf(String.valueOf(orderFillTransaction.get('accountBalance')));
                	Decimal profit = Decimal.valueOf(String.valueOf(orderFillTransaction.get('pl')));
                    Decimal profitPercentage = (profit / algoTrade.Start_Balance__c) * 100;
                    algoTrade.Close_Date_Time__c = endDateTime;
                    algoTrade.Profit__c = profit;
                    algoTrade.Profit_Percentage__c = profitPercentage;
                    
                    update algoTrade;

                }
                if (secondTradeData != null) {
                
                    String index = accFirst.Id + '-' + accFirst.Oanda_Account_Id__c + '-' + secondTradeParts[1];
                    accFirst.Second_Trade__c = '';
                    update accFirst;
                    
                    Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res2.getBody());
                    Map<String, Object> orderFillTransaction = (Map<String, Object>) responseMap.get('orderFillTransaction');
                    
                    String timeStr = String.valueOf(orderFillTransaction.get('time'));
                    timeStr = timeStr.substring(0, timeStr.length() - 1);
                    timeStr = timeStr.substring(0, timeStr.indexOf('.'));
                    timeStr = timeStr.replace('T', ' ');
        
                         
                    Datetime endDateTime =  Datetime.valueOf(timeStr);
                    //Datetime endDateTime = (Datetime) orderFillTransaction.get('time');
                    
                    Algo_Trade__c algoTrade = [SELECT Id, Trade_ID__c,
                                                      Close_Date_Time__c, Profit__c,
                                                      Profit_Percentage__c, Start_Balance__c
                                                      FROM Algo_Trade__c WHERE Unique_Id__c = :index];
                    Decimal accountBalance = Decimal.valueOf(String.valueOf(orderFillTransaction.get('accountBalance')));
                	Decimal profit = Decimal.valueOf(String.valueOf(orderFillTransaction.get('pl')));
                    Decimal profitPercentage = (profit / algoTrade.Start_Balance__c) * 100;
                    algoTrade.Close_Date_Time__c = endDateTime;
                    algoTrade.Profit__c = profit;
                    algoTrade.Profit_Percentage__c = profitPercentage;
                    
                    update algoTrade;
                }
                
                if (thirdTradeData != null) {
                
                    String index = accFirst.Id + '-' + accFirst.Oanda_Account_Id__c + '-' + thirdTradeParts[1];
                    accFirst.Third_Trade__c = '';
                    update accFirst;
                    
                    Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res3.getBody());
                    Map<String, Object> orderFillTransaction = (Map<String, Object>) responseMap.get('orderFillTransaction');
                    
                    String timeStr = String.valueOf(orderFillTransaction.get('time'));
                    timeStr = timeStr.substring(0, timeStr.length() - 1);
                    timeStr = timeStr.substring(0, timeStr.indexOf('.'));
                    timeStr = timeStr.replace('T', ' ');
        
                         
                    Datetime endDateTime =  Datetime.valueOf(timeStr);
                    //Datetime endDateTime = (Datetime) orderFillTransaction.get('time');
                    
                    Algo_Trade__c algoTrade = [SELECT Id, Trade_ID__c,
                                                      Close_Date_Time__c, Profit__c,
                                                      Profit_Percentage__c, Start_Balance__c
                                                      FROM Algo_Trade__c WHERE Unique_Id__c = :index];
                    Decimal accountBalance = Decimal.valueOf(String.valueOf(orderFillTransaction.get('accountBalance')));
                	Decimal profit = Decimal.valueOf(String.valueOf(orderFillTransaction.get('pl')));
                    Decimal profitPercentage = (profit / algoTrade.Start_Balance__c) * 100;
                    algoTrade.Close_Date_Time__c = endDateTime;
                    algoTrade.Profit__c = profit;
                    algoTrade.Profit_Percentage__c = profitPercentage;
                    
                    update algoTrade;
                }
                
                                    
                if (tradeSignal.comment == 'Long' || tradeSignal.comment == 'Short') { 
                    placeTradeFuture(strBody);
                    return;
                }
                
                
                
                
            }
        } else {
            // Place first trade
            req.setBody(jsonBody);
            
            HTTPResponse res = http.send(req);
            
            if (res.getStatusCode() == 201) {
                // Parse the response to get the trade ID
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                Map<String, Object> orderFillTransaction = (Map<String, Object>) responseMap.get('orderFillTransaction');
                String tradeId = (String) orderFillTransaction.get('id');
                Decimal accountBalance = Decimal.valueOf(String.valueOf(orderFillTransaction.get('accountBalance')));
                String timeStr = String.valueOf(orderFillTransaction.get('time'));
                timeStr = timeStr.substring(0, timeStr.length() - 1);
                timeStr = timeStr.substring(0, timeStr.indexOf('.'));
                timeStr = timeStr.replace('T', ' ');

                 
                Datetime startDateTime =  Datetime.valueOf(timeStr);
                String index = accFirst.Id + '-' + accFirst.Oanda_Account_Id__c + '-' + tradeId;
    
                accFirst.First_Trade__c = tradeSignal.side + '-' + tradeId;
                update accFirst;
                
                Algo_Trade__c tradeInsert = new Algo_Trade__c();
                tradeInsert.Trading_Account__c = accFirst.Id;
                tradeInsert.Open_Date_Time__c = startDateTime;
                tradeInsert.Unique_Id__c = index;
                tradeInsert.Start_Balance__c = accountBalance;
                tradeInsert.Trade_Id__c = tradeId;
                
                insert tradeInsert;
            }
        }
        

        


        System.debug('REQ | ' + req + ' BODY ' + jsonBody);

        Account acc = [Select Id, Second_SS__c, Oanda_Account_Id__c FROM Account Where Id  ='0017Q00001TwBUCQA3'];
		
        

        System.debug('HERE ' +acc.Second_SS__c);
        
        /**
         * If secondss is filled and comment is long or short, close trade and then place new
         */

        /*if (acc.Second_SS__c == null) {
            //Http http = new Http();
            //HTTPResponse res = http.send(req);
    
            if (res.getStatusCode() == 201) {
                // Parse the response to get the trade ID
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                Map<String, Object> orderFillTransaction = (Map<String, Object>) responseMap.get('orderFillTransaction');
                String tradeId = (String) orderFillTransaction.get('id');
                Decimal accountBalance = Decimal.valueOf(String.valueOf(orderFillTransaction.get('accountBalance')));
                String timeStr = String.valueOf(orderFillTransaction.get('time'));
                timeStr = timeStr.substring(0, timeStr.length() - 1);
                timeStr = timeStr.substring(0, timeStr.indexOf('.'));
                timeStr = timeStr.replace('T', ' ');

                 
                Datetime startDateTime =  Datetime.valueOf(timeStr);
                String index = acc.Id + '-' + acc.Oanda_Account_Id__c + '-' + tradeId;
    
                acc.Second_SS__c = tradeId;
                update acc;
                
                Algo_Trade__c tradeInsert = new Algo_Trade__c();
                tradeInsert.Trading_Account__c = acc.Id;
                tradeInsert.Open_Date_Time__c = startDateTime;
                tradeInsert.Unique_Id__c = index;
                tradeInsert.Start_Balance__c = accountBalance;
                tradeInsert.Trade_Id__c = tradeId;
                
                insert tradeInsert;
                /*Algorithmic_Trade__x tradeInsert = new Algorithmic_Trade__x();
                tradeInsert.Account__c = acc.Id;
                tradeInsert.Open_Date_Time__c = startDateTime;
                tradeInsert.ExternalId = index;
                tradeInsert.Unique_Id__c = index;
                tradeInsert.Start_Balance__c = accountBalance;
                tradeInsert.Trade_Id__c = tradeId;
                
                //QueueableInsertDynamo job = new QueueableInsertDynamo(tradeInsert, 'insert');
        		//System.enqueueJob(job);
            } else {
                System.debug('Failed to place trade: ' + res.getBody());
            }
        } else {
            
            
            
            
            HTTPResponse res = closeTrade(acc.Second_SS__c, '101-004-23424312-002', '3ca1fa8d639245ae65178cdfda22708e-82f12203086ee753781867a146bde7f0');
            String index = acc.Id + '-' + acc.Oanda_Account_Id__c + '-' + acc.Second_SS__c;
            acc.Second_SS__c = '';
            update acc;
            
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            Map<String, Object> orderFillTransaction = (Map<String, Object>) responseMap.get('orderFillTransaction');
            
            String timeStr = String.valueOf(orderFillTransaction.get('time'));
            timeStr = timeStr.substring(0, timeStr.length() - 1);
            timeStr = timeStr.substring(0, timeStr.indexOf('.'));
            timeStr = timeStr.replace('T', ' ');

                 
            Datetime endDateTime =  Datetime.valueOf(timeStr);
            //Datetime endDateTime = (Datetime) orderFillTransaction.get('time');
            
            Algo_Trade__c algoTrade = [SELECT Id, Trade_ID__c,
                                              Close_Date_Time__c, Profit__c,
                                              Profit_Percentage__c, Start_Balance__c
                                              FROM Algo_Trade__c WHERE Unique_Id__c = :index];
            Decimal accountBalance = Decimal.valueOf(String.valueOf(orderFillTransaction.get('accountBalance')));
            Decimal profit = accountBalance - algoTrade.Start_Balance__c;
            Decimal profitPercentage = (profit / algoTrade.Start_Balance__c) * 100;
            algoTrade.Close_Date_Time__c = endDateTime;
            algoTrade.Profit__c = profit;
            algoTrade.Profit_Percentage__c = profitPercentage;
            
            update algoTrade;
            
            if (tradeSignal.comment == 'Long' || tradeSignal.comment == 'Short') {
                /*HTTPResponse res = closeTrade(acc.Second_SS__c, '101-004-23424312-002', '3ca1fa8d639245ae65178cdfda22708e-82f12203086ee753781867a146bde7f0');
                String index = acc.Id + '-' + acc.Oanda_Account_Id__c + '-' + acc.Second_SS__c;
                acc.Second_SS__c = '';
                update acc;
                
                placeTradeFuture(strBody);
                return;
            }
            
            /*Algorithmic_Trade__x algoTrade = [SELECT Id, Trade_ID__c,
                                              Close_Date_Time__c, Profit__c,
                                              Profit_Percentage__c, Start_Balance__c
                                              FROM Algorithmic_Trade__x WHERE Unique_Id__c = :index];
            Decimal accountBalance = (Decimal) orderFillTransaction.get('accountBalance');
            Decimal profit = accountBalance - algoTrade.Start_Balance__c;
            Decimal profitPercentage = (profit / algoTrade.Start_Balance__c) * 100;
            algoTrade.Close_Date_Time__c = endDateTime;
            algoTrade.Profit__c = profit;
            algoTrade.Profit_Percentage__c = profitPercentage;

            //QueueableInsertDynamo job = new QueueableInsertDynamo(algoTrade, 'update');
        	//System.enqueueJob(job);
            //Database.updateImmediate(algoTrade);
            //elapseTime  

            return;
            
        }*/
    }


    private class SignalTrade {
        String side;
        Decimal price;
        Integer contracts;
        String comment;
    }
}