public class GetEconomicCalendar {
	public static void getNews() {
        System.debug('Updating News call ------------');
        
        String apiKey = 'API_KEYd57O3YC2TKKQL36HLHMXVXO27MFMJ5D1';
        
        /*String f = DateTime.now().addDays(-7).formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        Map<String, String> queryParams = new Map<String, String>{
            'from' => f
            
        };*/
        
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        //String apiUrl = 'https://api.finage.co.uk/economic-calendar?from=2023-03-12&to=2020-03-17&apikey=' + apiKey;
        
        //req.setEndpoint('https://api.apilayer.com/exchangerates_data/convert?to=EUR&from=USD&amount=92.82');
        //req.setEndpoint('https://api-fxtrade.oanda.com/v3/accounts'); //Get All Accounts
       // DateTime currentDate = DateTime.now();
        //System.debug(currentDate);
		//String isoDatetime = currentDate.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSSSS\'Z\'');
		//apiUrl += '?to=' + EncodingUtil.urlEncode(isoDatetime, 'UTF-8');
		String apiUrl = 'https://api.finage.co.uk/economic-calendar?from=2020-10-01&to=2020-11-01&apikey=API_KEYd57O3YC2TKKQL36HLHMXVXO27MFMJ5D1';
        req.setEndpoint(apiUrl);

        req.setMethod('GET');
        /*Map<String, String> headers = new Map<String, String>{
            'Authorization' => 'Bearer ' + apiKey
        };
        req.setHeader('Authorization', 'Bearer ' + apiKey);*/
        HttpResponse res = h.send(req);
        
        System.debug('Status Code: ' + res.getStatusCode());
        
        if (res.getStatusCode() == 200) {
            
            Map<String, Object> jsonResponse = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
            system.debug('json here--------');
            system.debug(jsonResponse);
    		/*List<Object> transactions = (List<Object>)jsonResponse.get('pages');
            system.debug('transactions here--------');
            system.debug(transactions);
            system.debug('page here--------');
            system.debug(transactions[1]);
            page = transactions[1].toString();*/
            
           
        } else {
        }
	}
}