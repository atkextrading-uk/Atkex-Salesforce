public class ProxyServer {
    @AuraEnabled
    public static String makeRequest(String url) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setMethod('GET');
        Http http = new Http();
        HTTPResponse res = http.send(req);
        return res.getBody();
    }
}