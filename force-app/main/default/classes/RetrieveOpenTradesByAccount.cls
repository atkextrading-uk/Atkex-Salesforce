public with sharing class RetrieveOpenTradesByAccount {


    // Output wrapper for Flow
    
    public class FlowResult {
        @InvocableVariable public Boolean success;
        @InvocableVariable public String message;
        @InvocableVariable public Integer statusCode;
        @InvocableVariable public String effectiveEndpoint;
        @InvocableVariable @AuraEnabled public List<OpenTradeDTO> trades;
    }

    // Trade record wrapper
    public class Trade {
        @InvocableVariable public String id;
        @InvocableVariable public String type;
        @InvocableVariable public String symbol;
        @InvocableVariable  public String timeString;
        @InvocableVariable public Decimal stopLoss;
        @InvocableVariable public Decimal takeProfit;
    }

    // Flow entry point
    @InvocableMethod(label='Retrieve Open Trades (Single Trading Account)' callout=true)
    public static List<FlowResult> run(List<Id> recordIds) {
        List<FlowResult> out = new List<FlowResult>();
        FlowResult res = new FlowResult();
        out.add(res);
        res.trades = new List<OpenTradeDTO>();

        // Null input handling
        if (recordIds == null || recordIds.isEmpty() || recordIds[0] == null) {
            res.success = false;
            res.message = 'No Trading_Account__c Id provided.';
            return out;
        }

        Id taId = recordIds[0];

        // Retrieve Trading_Account__c (single SOQL, no loop)
        Trading_Account__c ta = [
            SELECT Id, MetaTrader_ID__c
            FROM Trading_Account__c
            WHERE Id = :taId
            LIMIT 1
        ];

        if (ta == null || String.isBlank(ta.MetaTrader_ID__c)) {
            res.success = false;
            res.message = 'MetaTrader_ID__c is null/blank on Trading_Account__c ' + String.valueOf(taId);
            return out;
        }

        // Build endpoint with Named Credential
        String base = 'callout:Atkex_Trading/api/position/accounts/';
        String accountId = ta.MetaTrader_ID__c;

        String endpoint = base + EncodingUtil.urlEncode(accountId, 'UTF-8') + '/positions';
        res.effectiveEndpoint = endpoint != null ? endpoint.replace('callout:', '') : null;

        // HTTP callout
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setEndpoint(endpoint);
        req.setTimeout(120000);
        System.debug(endpoint);
        try {
            HttpResponse resp = h.send(req);
            
             System.debug(resp.getBody());
            res.statusCode = (resp != null) ? resp.getStatusCode() : null;

            if (resp == null) {
                res.success = false;
                res.message = 'No response from API.';
                return out;
            }

            if (resp.getStatusCode() < 200 || resp.getStatusCode() >= 300) {
                res.success = false;
                res.message = 'API error: ' + resp.getStatus();
                return out;
            }

            // Parse trades JSON
            List<Object> parsed = (List<Object>) JSON.deserializeUntyped(resp.getBody());
            if (parsed != null) {
                for (Object o : parsed) {
                    Map<String, Object> row = (Map<String, Object>) o;
                    OpenTradeDTO t = new OpenTradeDTO();
                    t.id     = row.containsKey('id')     ? String.valueOf(row.get('id'))     : null;
                    t.type   = row.containsKey('type')   ? String.valueOf(row.get('type'))   : null;
                    t.symbol = row.containsKey('symbol') ? String.valueOf(row.get('symbol')) : null;
                    t.timeString = row.containsKey('timeString') ? formatIsoToUk(row.get('timeString')): null;
                    t.stopLoss = row.containsKey('stopLoss') ? Double.valueOf(row.get('stopLoss')) : null;
                    t.takeProfit = row.containsKey('takeProfit') ? Double.valueOf(row.get('takeProfit')) : null;
                    t.openPrice = row.containsKey('openPrice') ? Double.valueOf(row.get('openPrice')) : null;
                    res.trades.add(t);
                }
            }

            res.success = true;
            res.message = 'Retrieved ' + res.trades.size() + ' trades.';
        } catch (System.CalloutException e) {
            res.success = false;
            res.message = 'Callout exception: ' + e.getMessage();
        } catch (Exception e) {
            res.success = false;
            res.message = 'Unexpected exception: ' + e.getMessage();
        }

        return out;
    }
    private static String formatIsoToUk(Object val) {
        if (val == null) return null;
        try {
            // Parse the ISO string into a Datetime
            Datetime dt = (Datetime) JSON.deserialize('"' + String.valueOf(val) + '"', Datetime.class);
            // Format as dd/MM/yyyy HH:mm (24-hour clock, GMT safe)
            return dt.format('dd/MM/yyyy HH:mm');
        } catch (Exception e) {
            System.debug('Failed to parse time: ' + val + ' => ' + e.getMessage());
            return String.valueOf(val); // fallback: return raw string
        }
    }
}

