public with sharing class UpdateStrategyInvoker {

    public class Result {
        @InvocableVariable public Boolean success;
        @InvocableVariable public String  message;
        @InvocableVariable public Integer statusCode;
        @InvocableVariable public String  responseBody;
        @InvocableVariable public String  effectiveEndpoint;
    }

    @InvocableMethod(
        label='Update Strategy on Pi'
        description='Calls the Pi API /api/strategy/create/{External_Id__c} endpoint to sync strategy'
        callout=true
    )
    public static List<Result> run(List<Id> strategyIds) {
        List<Result> results = new List<Result>();

        if (strategyIds == null || strategyIds.isEmpty()) {
            Result r = new Result();
            r.success = false;
            r.message = 'No Strategy__c Ids provided.';
            results.add(r);
            return results;
        }

        // One SOQL query outside loops
        List<Strategy__c> strategies = [
            SELECT Id, External_Id__c,
                   Trading_Account__r.MetaTrader_ID__c
            FROM Strategy__c
            WHERE Id IN :strategyIds
        ];

        Http http = new Http();

        for (Strategy__c strat : strategies) {
            Result r = new Result();
            results.add(r);

            if (strat == null) {
                r.success = false;
                r.message = 'Null Strategy record';
                continue;
            }
            if (String.isBlank(strat.External_Id__c)) {
                r.success = false;
                r.message = 'External_Id__c is blank for Strategy ' + strat.Id;
                continue;
            }
            if (strat.Trading_Account__r == null ||
                String.isBlank(strat.Trading_Account__r.MetaTrader_ID__c)) {
                r.success = false;
                r.message = 'Trading_Account__c.MetaTrader_ID__c is blank for Strategy ' + strat.Id;
                continue;
            }

            // Build endpoint (Named Credential)
            String baseUrl = 'callout:Atkex_Trading/api/strategy/create/';
            String endpoint = baseUrl + EncodingUtil.urlEncode(strat.External_Id__c, 'UTF-8');
            r.effectiveEndpoint = endpoint.replace('callout:', '');

            // Build body
            Map<String, Object> body = new Map<String, Object>{
                'sfStrategyId' => strat.Id,
                'accountId'    => strat.Trading_Account__r.MetaTrader_ID__c
            };

            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('PUT');
            req.setTimeout(120000);
            req.setHeader('Content-Type', 'application/json');
            req.setBody(JSON.serialize(body));


            try {
                HttpResponse resp = http.send(req);
                r.statusCode   = resp != null ? resp.getStatusCode() : null;
                r.responseBody = resp != null ? resp.getBody() : null;
                r.success      = r.statusCode != null && r.statusCode >= 200 && r.statusCode < 300;
                r.message      = r.success ? 'Callout completed.' :
                                 'Callout failed: ' + (resp != null ? resp.getStatus() : 'No response');
            } catch (System.CalloutException e) {
                r.success = false;
                r.message = 'Callout exception: ' + e.getMessage();
            } catch (Exception e) {
                r.success = false;
                r.message = 'Unexpected exception: ' + e.getMessage();
            }
        }

        return results;
    }
}
