public with sharing class ImportMetatraderTradesByAccount {

    // Optional: direct-use helper if you ever call it from Apex
    public class SingleResult {
        @InvocableVariable public Boolean success;
        @InvocableVariable public String message;
        @InvocableVariable public Integer statusCode;
        @InvocableVariable public String responseBody;
        @InvocableVariable public String effectiveEndpoint;
    }

    // Flow passes a list; we only ever process the first element.
    @InvocableMethod(label='Import MetaTrader Trades (Single Trading Account)' callout=true)
    public static List<SingleResult> run(List<Id> recordIds) {
        List<SingleResult> out = new List<SingleResult>();
        SingleResult res = new SingleResult();
        out.add(res);

        // Null / empty input handling
        if (recordIds == null || recordIds.isEmpty() || recordIds[0] == null) {
            res.success = false;
            res.message = 'No Trading_Account__c Id provided.';
            return out;
        }

        Id taId = recordIds[0];

        // Single SOQL (no loops)
        Trading_Account__c ta = [
            SELECT Id, Account__c, Account_Code__c, MetaTrader_ID__c, Latest_Update_Date__c, Balance__c, Max_R__c
              FROM Trading_Account__c
             WHERE Id = :taId
             LIMIT 1
        ];

        // Validate required fields
        String sfAccountId = (ta != null && ta.Id != null) ? String.valueOf(ta.Id) : null;
        String mtAccountId = (ta != null && !String.isBlank(ta.MetaTrader_ID__c)) ? ta.MetaTrader_ID__c : null;
        String accountCode = (ta != null && !String.isBlank(ta.Account_Code__c)) ? ta.Account_Code__c : null;

        if (sfAccountId == null) {
            res.success = false; res.message = 'Account__c is null on Trading_Account__c ' + String.valueOf(taId);
            return out;
        }
        if (mtAccountId == null) {
            res.success = false; res.message = 'MetaTrader_ID__c is null/blank on Trading_Account__c ' + String.valueOf(taId);
            return out;
        }
        if (accountCode == null) {
            res.success = false; res.message = 'Account_Code__c is null/blank on Trading_Account__c ' + String.valueOf(taId);
            return out;
        }

        // Build from/to in UTC (default from = last update or 14 days ago)
        Datetime toDt = Datetime.now();
        Datetime fromDt = (ta != null && ta.Latest_Update_Date__c != null) ? ta.Latest_Update_Date__c : toDt.addDays(-14);
        String fromIso = formatIso8601(fromDt); // e.g. 2025-09-01T11:00:00Z
        String toIso   = formatIso8601(toDt);

        // Endpoint via Named Credential
        String base = 'callout:Atkex_Trading/api/trades/import/metatrader';

        // Query string (null-safe & URL-encoded)
        String qs = '';
        qs = appendParam(qs, 'sfAccountId', sfAccountId);
        qs = appendParam(qs, 'mtAccountId', mtAccountId);
        qs = appendParam(qs, 'accountCode', accountCode);
        qs = appendParam(qs, 'from', fromIso);
        qs = appendParam(qs, 'to', toIso);
        qs = appendParam(qs, 'openBalance', String.valueOf(ta.Balance__c));
        qs = appendParam(qs, 'rValue', String.valueOf(ta.Max_R__c));

        String endpoint = base + qs;
        res.effectiveEndpoint = endpoint != null ? endpoint.replace('callout:', '') : null;

        // HTTP callout
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setEndpoint(endpoint);
        req.setTimeout(120000);

        try {
            HttpResponse resp = h.send(req);
            res.statusCode   = (resp != null) ? resp.getStatusCode() : null;
            res.responseBody = (resp != null) ? resp.getBody()       : null;
            res.success      = (res.statusCode != null && res.statusCode >= 200 && res.statusCode < 300);
            res.message      = res.success ? 'Callout completed.' : 'Callout failed: ' + (resp != null ? resp.getStatus() : 'No response');

            // On success, update Latest_Update_Date__c = now (single DML with try/catch)
            if (res.success && ta != null) {
                Trading_Account__c upd = new Trading_Account__c(Id = ta.Id, Latest_Update_Date__c = toDt);
                try {
                    update upd;
                } catch (DmlException d) {
                    System.debug(LoggingLevel.ERROR,
                        'Failed to update Latest_Update_Date__c on Trading_Account__c ' + String.valueOf(taId) + ': ' + d.getMessage());
                }
            }

        } catch (System.CalloutException e) {
            res.success = false;
            res.message = 'Callout exception: ' + e.getMessage();
        } catch (Exception e) {
            res.success = false;
            res.message = 'Unexpected exception: ' + e.getMessage();
        }

        return out;
    }

    // ===== Utilities =====

    private static String appendParam(String qs, String key, String value) {
        if (String.isBlank(value)) return qs;
        String pair = key + '=' + EncodingUtil.urlEncode(value, 'UTF-8');
        return (String.isBlank(qs) ? '?' : qs + '&') + pair;
    }

    private static String formatIso8601(Datetime dt) {
        if (dt == null) return null; // null pointer expectation handling
        return dt.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
    }
}
