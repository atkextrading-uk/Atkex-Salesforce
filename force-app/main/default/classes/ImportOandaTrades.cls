public class ImportOandaTrades {

    @InvocableMethod(label='Get Oanda Trades')
    public static void getOandaTrades(List<FlowInputs> fi) { 
        Id accountId = fi[0].recordId;
        
        Account tradingAccount = [SELECT RecordTypeId
            FROM Account
            WHERE Id = :accountId];
       
		String metaTrader5RT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('MetaTrader5').getRecordTypeId();
        
        // Check record type
        if (String.valueOf(tradingAccount.RecordTypeId) == metaTrader5RT) {
            completeMetaTrader5Updates(fi);
        } else {
            completeOandaUpdates(fi);
        }
    }
    
    private static void completeMetaTrader5Updates(List<FlowInputs> fi) {
        Account tradingAccount = [SELECT Id, Oanda__c, Oanda_Latest_Ticket_Number__c, Oanda_Account_Id__c, Last_Update_Date__c
            FROM Account
            WHERE Id = :fi[0].recordId];


        System.debug('getMetaTrades');
        //String apiKey = 'ad066bf167934d6e651cb1062f8e3c54-61359152af15b810bcbaf587afb8c0d6';
        String apiKey = tradingAccount.Oanda__c;
        
        Http h = new Http();
        HttpRequest req = new HttpRequest();//	https://api-fxpractice.oanda.com    callout:Oanda_Credential
        ///users/current/accounts/6667ecda-b334-4fdb-9ea6-60c74e6745cc/history-deals/time/2025-07-04T00:00:00.000Z/2025-08-30T23:00:00.000Z
        //String apiUrl = 'callout:MetaTrader5' + '/users/current/accounts/' + tradingAccount.Oanda_Account_Id__c + '/history-deals/time/' + tradingAccount.Last_Update_Date__c.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'') + '/' + Datetime.now().formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');

        String apiUrl = 'https://mt-client-api-v1.london.agiliumtrade.ai' + '/users/current/accounts/' + tradingAccount.Oanda_Account_Id__c + '/history-deals/time/' + tradingAccount.Last_Update_Date__c.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'') + '/' + Datetime.now().formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        req.setEndpoint(apiUrl);
 
        req.setMethod('GET');
        req.setHeader('auth-token', apiKey);
        req.setHeader('Authorization', 'Bearer ' + apiKey);
        System.debug('TEST REQ' + req);
        HttpResponse res = h.send(req);
        
        System.debug(res.getBody());
        
        //String jsonString = res.getBody().replace('time', 'transactionTime');
		/*RESTResponse.OandaTransactionsPage page = (RESTResponse.OandaTransactionsPage) JSON.deserialize(jsonString, RESTResponse.OandaTransactionsPage.class);     
        
        BatchUpdateTransactions myBatch = new BatchUpdateTransactions(Integer.valueOf(tradingAccount.Oanda_Latest_Ticket_Number__c), tradingAccount.Oanda_Account_Id__c, tradingAccount.Id, page.transactions);

        List<BatchUpdateTransactions> batchList = new List<BatchUpdateTransactions>();
        for (String pLoop : pages) {
            BatchUpdateTransactions myBatch = new BatchUpdateTransactions(pLoop, apiKey, Integer.valueOf(tradingAccount.Oanda_Latest_Ticket_Number__c), tradingAccount.Oanda_Account_Id__c, tradingAccount.Id);
            batchList.add(myBatch);
        }
        Integer batchSize = 50;
        Database.executeBatch(myBatch, batchSize);*/
        
    }
    
    private static void completeOandaUpdates(List<FlowInputs> fi) {
         Account tradingAccount = [SELECT Id, Oanda__c, Oanda_Latest_Ticket_Number__c, Oanda_Account_Id__c
            FROM Account
            WHERE Id = :fi[0].recordId];


        System.debug('getOandaTrades');
        //String apiKey = 'ad066bf167934d6e651cb1062f8e3c54-61359152af15b810bcbaf587afb8c0d6';
        String apiKey = tradingAccount.Oanda__c;
        
        Http h = new Http();
        HttpRequest req = new HttpRequest();//	https://api-fxpractice.oanda.com    callout:Oanda_Credential
        String apiUrl = 'callout:Oanda_Credential' + '/v3/accounts/' + tradingAccount.Oanda_Account_Id__c + '/transactions/sinceid?id=' + tradingAccount.Oanda_Latest_Ticket_Number__c;
        req.setEndpoint(apiUrl);
 
        req.setMethod('GET');
        Map<String, String> headers = new Map<String, String>{
            'Authorization' => 'Bearer ' + apiKey
        };
        req.setHeader('Authorization', 'Bearer ' + apiKey);
        System.debug('TEST REQ' + req);
        HttpResponse res = h.send(req);

        /*List<String> pages = new List<String>();
         
        if (res.getStatusCode() == 200) {
            RESTResponse.OandaTransactions oandaTransactions = (RESTResponse.OandaTransactions) JSON.deserialize(res.getBody(), RESTResponse.OandaTransactions.class);
            
    		pages = (List<String>)oandaTransactions.pages;
            
        }*/
        
        String jsonString = res.getBody().replace('time', 'transactionTime');
		RESTResponse.OandaTransactionsPage page = (RESTResponse.OandaTransactionsPage) JSON.deserialize(jsonString, RESTResponse.OandaTransactionsPage.class);     
        
        BatchUpdateTransactions myBatch = new BatchUpdateTransactions(Integer.valueOf(tradingAccount.Oanda_Latest_Ticket_Number__c), tradingAccount.Oanda_Account_Id__c, tradingAccount.Id, page.transactions);

        /*List<BatchUpdateTransactions> batchList = new List<BatchUpdateTransactions>();
        for (String pLoop : pages) {
            BatchUpdateTransactions myBatch = new BatchUpdateTransactions(pLoop, apiKey, Integer.valueOf(tradingAccount.Oanda_Latest_Ticket_Number__c), tradingAccount.Oanda_Account_Id__c, tradingAccount.Id);
            batchList.add(myBatch);
        }*/
        Integer batchSize = 50;
        Database.executeBatch(myBatch, batchSize);
        /*for (BatchUpdateTransactions batch : batchList) {
            Database.executeBatch(batch, batchSize);
        }*/
    }

    /*@InvocableMethod(label='Start Oanda live transations')
    public static void startOandaLiveTransactions(List<FlowInputs> fi) {      
        QueuableOandaLiveTransactions qClass = new QueuableOandaLiveTransactions(fi[0].recordId);
        Id batchId = System.enqueueJob(qClass);
        
    }*/

    public class FlowInputs {
        @InvocableVariable
        public Id recordId;
    }
}