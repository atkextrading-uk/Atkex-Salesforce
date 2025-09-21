// Simple Invocable to call the Atkex /api/accounts/update endpoint.
// No field updates are done — it just performs the callout and returns status.
public with sharing class UpdateMetatraderAccountDetails {

    public class Result {
        @InvocableVariable public Boolean success;
        @InvocableVariable public String  message;
        @InvocableVariable public Integer statusCode;
        @InvocableVariable public String  responseBody;
        @InvocableVariable public String  effectiveEndpoint;
    }

    @InvocableMethod(label='Trigger MetaTrader Account Update'
                     description='Calls the Atkex /api/accounts/update endpoint for a Trading_Account__c record'
                     callout=true)
    public static List<Result> run(List<Id> recordIds) {
        List<Result> outs = new List<Result>();
        Result r = new Result();
        outs.add(r);

        if (recordIds == null || recordIds.isEmpty() || recordIds[0] == null) {
            r.success = false;
            r.message = 'No Trading_Account__c Id provided.';
            return outs;
        }

        Id taId = recordIds[0];

        Trading_Account__c ta = [
            SELECT Id, MetaTrader_ID__c
            FROM Trading_Account__c
            WHERE Id = :taId
            LIMIT 1
        ];

        if (ta == null) {
            r.success = false;
            r.message = 'Trading_Account__c not found: ' + String.valueOf(taId);
            return outs;
        }
        if (String.isBlank(ta.MetaTrader_ID__c)) {
            r.success = false;
            r.message = 'MetaTrader_ID__c is blank on Trading_Account__c ' + ta.Id;
            return outs;
        }

        // Build endpoint (uses Named Credential 'Atkex_Trading')
        String base = 'callout:Atkex_Trading/api/accounts/update';
        String qs   = '?salesforceAccountId=' + EncodingUtil.urlEncode(String.valueOf(ta.Id), 'UTF-8')
                    + '&metatraderAccountId=' + EncodingUtil.urlEncode(ta.MetaTrader_ID__c, 'UTF-8');

        String endpoint = base + qs;
        r.effectiveEndpoint = endpoint.replace('callout:', '');

        Http h   = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setTimeout(120000);

        try {
            HttpResponse resp = h.send(req);
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

        return outs;
    }
}
