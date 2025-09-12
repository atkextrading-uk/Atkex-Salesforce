public with sharing class TwilioAPIHandler {
    public TwilioAPIHandler() {

    }
    public static void makeCall() {
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        String apiUrl = 'https://api.twilio.com/2010-04-01/Accounts/AC1c1aed21e5acfa960179f278f5bd2c2f/Calls.json';
        req.setEndpoint(apiUrl);
 
        req.setMethod('POST');
        
        req.setHeader('Authorization', 'Basic QUMxYzFhZWQyMWU1YWNmYTk2MDE3OWYyNzhmNWJkMmMyZjo2OTdjY2I1M2NiNzZkZjRhY2I0MGU0MzY2ZjRlNjI3OA==');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        
		String toNumber = '+447443221519';
        String fromNumber = '+441793540749';
        String message = 'Trading View Alert. Moo Poo';
        
        String formData = 'To=' + EncodingUtil.urlEncode(toNumber, 'UTF-8') +
                          '&From=' + EncodingUtil.urlEncode(fromNumber, 'UTF-8') +
                          '&Body=' + EncodingUtil.urlEncode(message, 'UTF-8') + '&Url=http://demo.twilio.com/docs/voice.xml';
        //String formData = 'To=++447443221519&From=+447481343264&Url=http://demo.twilio.com/docs/voice.xml';
        req.setBody(formData);
         
        HttpResponse res = h.send(req);

        System.debug('Body: ' + res.getBody());
    }
}