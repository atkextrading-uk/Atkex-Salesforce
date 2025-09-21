public with sharing class TradingAccountController {
    public class CreateRequest {
        @AuraEnabled public String server;
        @AuraEnabled public String platform;              // "mt4" | "mt5"
        @AuraEnabled public String type;                  // "cloud-g1"
        @AuraEnabled public String baseCurrency;          // "USD"
        //@AuraEnabled public String provisioningProfileId; // from earlier step
        @AuraEnabled public String login;
        @AuraEnabled public String password;
        @AuraEnabled public List<String> copyFactoryRoles;
        @AuraEnabled public String sfTradingAccountId;    // optional for write-back
        @AuraEnabled public String sfAccountName;
    }
    public class CreateResponse {
        @AuraEnabled public Integer status;
        @AuraEnabled public String  statusText;
        @AuraEnabled public String  body; // expected: {"id":"...","state":"..."}
    }

    @AuraEnabled
    public static CreateResponse createAccount(String reqJson) {
        if (String.isBlank(reqJson)) throw new AuraHandledException('Request JSON cannot be blank.');
        HttpRequest httpReq = new HttpRequest();
        Http http = new Http();
        httpReq.setMethod('POST');
        httpReq.setEndpoint('callout:Atkex_Trading' + '/api/accounts/create-account');
        httpReq.setHeader('Content-Type', 'application/json');
        httpReq.setBody(reqJson);

        CreateResponse wrap = new CreateResponse();
        try {
            HttpResponse res = http.send(httpReq);
            wrap.status = res != null ? res.getStatusCode() : 0;
            wrap.statusText = res != null ? res.getStatus() : 'No response';
            wrap.body = res != null ? res.getBody() : null;
        } catch (System.CalloutException ex) {
            System.debug(LoggingLevel.ERROR, 'TradingAccountController.createAccount CalloutException: ' + ex.getMessage());
            throw new AuraHandledException('Callout failed: ' + ex.getMessage());
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'TradingAccountController.createAccount Unexpected: ' + e.getMessage());
            throw new AuraHandledException('Unexpected error: ' + e.getMessage());
        }
        return wrap;
    }
}
