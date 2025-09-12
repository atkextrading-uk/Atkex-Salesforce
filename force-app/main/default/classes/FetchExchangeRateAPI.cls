public class FetchExchangeRateAPI {
    

    @future (callout=true)
    public static void convertAmount() {
        System.debug('convert ammount');
        
         String apiKey = 'uTwcRZsb6p84JCWqGxVvQE4zpr8g6K8j';
        
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        //req.setEndpoint('https://api.apilayer.com/exchangerates_data/convert?to=EUR&from=USD&amount=92.82');
        req.setEndpoint('https://api.apilayer.com/exchangerates_data/' + '2023-02-10');
        req.setMethod('GET');
        req.setHeader('apikey', apiKey);
        HttpResponse res = h.send(req);
        
        if (res.getStatusCode() == 200) {
            // Handle the successful response
            // Parse the JSON response and process it as needed
            // ...
            Map<String, Object> jsonData = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            
            System.debug(jsonData);
            
        } else {
            // Handle the error
            // ...
        }
        
        
        
        /*var myHeaders = new Headers();
        myHeaders.append('apikey', "uTwcRZsb6p84JCWqGxVvQE4zpr8g6K8j");
        
        var requestOptions = {
          method: 'GET',
          redirect: 'follow',
          headers: myHeaders
        };
        
        fetch("https://api.apilayer.com/exchangerates_data/convert?to={to}&from={from}&amount={amount}", requestOptions)
          .then(response => response.text())
          .then(result => console.log(result))
          .catch(error => console.log('error', error));*/
    }
}