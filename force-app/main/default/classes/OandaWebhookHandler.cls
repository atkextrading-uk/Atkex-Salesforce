@RestResource(urlMapping='/oanda_webhook')
global class OandaWebhookHandler {
	@HttpPost
    global static void getStreamingData() {
    	RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString();
        
        //WebhookRequest webhookRequest = new WebhookRequest();
        HttpRequest request = new HttpRequest();
        Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
        //webhookRequest.parse(requestBody);
        
        //MyWebhookHandler handler = new MyWebhookHandler();
        //handler.handleRequest(webhookRequest);
    }
    
    /*@HttpPost
    global static void getOandaStreamingData() {
        String demoAccount = '101-004-23424312-001';
        String apiKey = '96574fb8b0d985e92144efb84b682538-5b197c055d6364868e51eba94e761b95';

        String endpoint = 'https://stream-fxpractice.oanda.com/v3/accounts/' + demoAccount + '/transactions/stream';
        String accessToken = apiKey;

        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('GET');
        request.setHeader('Authorization', 'Bearer ' + accessToken);
        request.setHeader('Content-Type', 'application/json');
        request.setTimeout(120000);

        Http http = new Http();
        HttpResponse response = http.send(request);
        
        system.debug('New trade');

        // Process the response and store the transaction data in Salesforce
        // ...
    }*/
    /*@HttpPost
    global static void handleWebhook() {
        // Parse the incoming JSON data
        String requestBody = RestContext.request.requestBody.toString();
        Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
        
        // Extract the relevant transaction data from the JSON
        String transactionType = (String) data.get('type');
        Map<String, Object> oandaTransaction = (Map<String, Object>) data.get('transaction');
        
        // Create a new transaction record in Salesforce and insert it
        SR_Hedge__c newTrade = new SR_Hedge__c(
            //Currency__c = (String) transaction.get('instrument'),
            //Amount__c = (Decimal) transaction.get('units'),
            //Price__c = (Decimal) oandaTransaction.get('price'),
            Open_Date_Time__c = DateTime.valueOf((String) oandaTransaction.get('time'))
        );
        System.debug('');
        //insert newTrade;
        
    }*/
       
}