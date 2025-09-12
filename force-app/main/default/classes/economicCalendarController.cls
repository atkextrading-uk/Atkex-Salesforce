public with sharing class economicCalendarController {
    public economicCalendarController() {

    }

    public static String getCalendarData() {
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://fxstreetapi.com/calendar');
        req.setMethod('GET');
        HttpResponse res = h.send(req);
        return res.getBody();
    }

    @AuraEnabled
    public static string getCal(){
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://www.forexfactory.com/calendar');
        req.setMethod('GET');
        HttpResponse resp = http.send(req);
        return resp.getBody();
    }

    @AuraEnabled
    public static string getCal2(){
        Http httpProtocol = new Http();
        HttpRequest request = new HttpRequest();
        String endpoint = 'https://www.forexfactory.com/calendar';
        request.setEndPoint(endpoint);
        request.setMethod('GET');
        HttpResponse response = httpProtocol.send(request);
        System.debug(response.getBody());
        return response.getBody();
    }
}