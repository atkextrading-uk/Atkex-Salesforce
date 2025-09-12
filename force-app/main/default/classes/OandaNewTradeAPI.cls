public class OandaNewTradeAPI {
    @InvocableMethod(label='Get New Trades')
    public static void getNewTrades() {
        System.debug('New trades call--------');
        
        String apiKey = '1b1b86ceac77054d99e29fd79648123b-bd2852af2421bff544e651a80c934829';
        
        /*String f = DateTime.now().addDays(-7).formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        Map<String, String> queryParams = new Map<String, String>{
            'from' => f
            
        };*/
        
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        String apiUrl = 'https://api-fxtrade.oanda.com/v3/accounts/001-004-6038873-004/transactions';
        //req.setEndpoint('https://api.apilayer.com/exchangerates_data/convert?to=EUR&from=USD&amount=92.82');
        //req.setEndpoint('https://api-fxtrade.oanda.com/v3/accounts'); //Get All Accounts
        DateTime currentDate = DateTime.now();
        System.debug(currentDate);
		String isoDatetime = currentDate.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSSSS\'Z\'');
		apiUrl += '?to=' + EncodingUtil.urlEncode(isoDatetime, 'UTF-8');
        req.setEndpoint(apiUrl);

        req.setMethod('GET');
        Map<String, String> headers = new Map<String, String>{
            'Authorization' => 'Bearer ' + apiKey
        };
        req.setHeader('Authorization', 'Bearer ' + apiKey);
        HttpResponse res = h.send(req);
        
        String page;
        
        if (res.getStatusCode() == 200) {
            
            Map<String, Object> jsonResponse = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
            system.debug('json here--------');
            system.debug(jsonResponse);
    		List<Object> transactions = (List<Object>)jsonResponse.get('pages');
            system.debug('transactions here--------');
            system.debug(transactions);
            system.debug('page here--------');
            system.debug(transactions[1]);
            page = transactions[1].toString();
            
           
        } else {
        }
        
        //Get page----------------------
        	Http h1 = new Http();
            HttpRequest req1 = new HttpRequest();
            req1.setMethod('GET');
            req1.setHeader('Authorization', 'Bearer ' + apiKey);
            HttpResponse res1 = h1.send(req);
            
            req1.setEndpoint(page);
            res1 = h1.send(req1);
            
            if (res1.getStatusCode() == 200) {
                Map<String, Object> jsonResponse1 = (Map<String, Object>)JSON.deserializeUntyped(res1.getBody());
                system.debug('page response--------------');
                system.debug(jsonResponse1);
            
                Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res1.getBody());
                List<Object> transactions = (List<Object>) result.get('transactions');
                
                System.debug('transactions-----------');
                
                
                   String closedTradeID;
                   for (Object tr : transactions) {
                       //System.debug(tr);
                       String type = (String) ((Map<String, Object>) tr).get('type');
                       String instrument = (String) ((Map<String, Object>) tr).get('instrument');
                       String dateAndTime = (String) ((Map<String, Object>) tr).get('time');
                       String batchId = (String) ((Map<String, Object>) tr).get('batchID');
                       String reason = (String) ((Map<String, Object>) tr).get('reason');
                       String orderId = (String) ((Map<String, Object>) tr).get('orderID');
                       String units = (String) ((Map<String, Object>) tr).get('units');
                       String price = (String) ((Map<String, Object>) tr).get('price');
                       String tradeId = (String) ((Map<String, Object>) tr).get('tradeID');
                       String accountBalance = (String) ((Map<String, Object>) tr).get('accountBalance');
                       String orderFillTransactionId = (String) ((Map<String, Object>) tr).get('orderFillTransactionID');
                       String profitLoss = (String) ((Map<String, Object>) tr).get('pl');
                       
                       

                       Integer orderIdPlusOne;
                       if (orderId != null) {
                       		orderIdPlusOne = integer.valueOf(orderId) + 1;
                       }
                       
                        if (type.equals('ORDER_FILL')) {
                            // This is a trade transaction
                            switch on reason {
                                when 'MARKET_ORDER' {
                                    Integer unitsComparison = integer.valueOf(units);
                                    String side;
                                    if (unitsComparison < 0) {
                                        side = 'Sell';
                                    } else {
                                        side = 'Buy';
                                    }
                                    system.debug('New order on ' + instrument + '|Date : ' + dateAndTime + '| Oanda TID' + orderIdPlusOne + '| Side' + side + '| Units' + units + '| Open Price' + price);
                                    
                                }
                                
                                when 'MARKET_ORDER_TRADE_CLOSE' {
                                    
                                    //System.debug(tradeCloseInfo);
                                    system.debug('Closed order details ' + instrument + '|Date : ' + dateAndTime + '| Oanda TID Closed ' + closedTradeID + '| Bal ' + accountBalance + '| Price ' + price + '| PL' + profitLoss);
                                    
                                    
                                   
                                }
                                when 'STOP_ORDER' {
                                    system.debug(batchId + 'SL Hit details ' + instrument + '|Date : ' + dateAndTime + '| Oanda TID Closed ' + closedTradeID + '| Bal ' + accountBalance + '| Price ' + price + '| PL' + profitLoss);
                                    
                                }
                                when 'TAKE_PROFIT_ORDER' {
                                    system.debug(batchId + 'TP Hit details ' + instrument + '|Date : ' + dateAndTime + '| Oanda TID Closed ' + closedTradeID + '| Bal ' + accountBalance + '| Price ' + price + '| PL' + profitLoss);

                                    
                                    
                                }
                                
                       		}
                            //String tradeID = (String) ((Map<String, Object>) tr).get('orderFillTransaction.tradeID');
                            // Do something with the trade ID
                            
                        } else if (type.equals('MARKET_ORDER') && reason.equals('TRADE_CLOSE')) {
                            
                               system.debug('market order trade closes');
                             Object closes = ((Map<String, Object>)tr).get('tradeClose');
                               System.debug(closes);
                            closedTradeID = (String) ((Map<String, Object>)closes).get('tradeID');
                            
                            
                        }
                }     
            }
            
    }
}