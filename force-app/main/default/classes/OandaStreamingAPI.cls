public with sharing class OandaStreamingAPI {
    public OandaStreamingAPI() {
        
    }
    @AuraEnabled(cacheable=true)
    public static void startStream() {
        
        
        // Event handler to process incoming events
        
        
        System.debug('starting stream');
        Boolean isRunning = true;

        while (isRunning) {
            System.debug('running');
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://stream-fxtrade.oanda.com/v3/accounts/001-004-6038873-001/transactions/stream?heartbeat=true');
            req.setHeader('Authorization', 'Bearer 4e8579e3db96dc19684f04d5a0f48eb8-455d6ddf527f93c43f1feaf69241a600');
            req.setHeader('Connection', 'Keep-Alive');
            req.setMethod('GET');
        	req.setTimeout(120000);

            Http http = new Http();
            HTTPResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                // Process the streaming data
                String response = res.getBody();
                System.debug(System.now() + '|' + response);
                // Parse the response to get the trade details
                // Update your local database or trigger other actions in your application
            } else {
                System.debug('Error: ' + res.getStatus());
            }

            // Wait for a short period before making the next request
            // This can help reduce the load on the API and prevent rate limiting
            // You can adjust the delay time based on your needs
            //Long delayMillis = 1000L;
            //System.sleep(delayMillis);
			//delay();
        
    	}
    }
}