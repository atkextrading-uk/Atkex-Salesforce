public with sharing class BulkModifyMtPositions {

    // ===== Flow I/O =====
    public class Request {
        @InvocableVariable(required=true) public Id tradingAccountId;
        @InvocableVariable public Decimal stopLoss;
        @InvocableVariable public Decimal takeProfit;
        @InvocableVariable public Boolean breakEven;
        @InvocableVariable public List<OpenTradeDTO> openTrades;
        @InvocableVariable(required=true) public List<String> positionIds;
        @InvocableVariable(required=false) public String apiToken; // optional: appended as ?token=...
    }

    public class Result {
        @InvocableVariable public Boolean success;
        @InvocableVariable public String  message;
        @InvocableVariable public Integer statusCode;
        @InvocableVariable public String  effectiveEndpoint;
        @InvocableVariable public String  responseBody;
        @InvocableVariable public Integer okCount;
        @InvocableVariable public Integer failCount;
    }

    @InvocableMethod(
        label='MT5: Bulk Modify Positions (Per-Trade SL/TP with DTO fallback)'
        description='Modify SL/TP for one or more MT5 positions. Uses request-level SL/TP when provided; otherwise falls back to each trade\'s current SL/TP from openTrades.'
        callout=true
    )
    public static List<Result> run(List<Request> requests) {
        // Standard invocable pattern: process element 0
        List<Result> out = new List<Result>();
        Result res = new Result(); out.add(res);

        if (requests == null || requests.isEmpty() || requests[0] == null) {
            res.success = false; res.message = 'No request payload provided.';
            return out;
        }
        Request reqIn = requests[0];

        // ==== Validate input ====
        if (reqIn.tradingAccountId == null) {
            res.success = false; res.message = 'tradingAccountId is required.'; return out;
        }
        if (reqIn.openTrades == null || reqIn.openTrades.isEmpty()) {
            res.success = false; res.message = 'openTrades collection is required (non-empty).'; return out;
        }

        // NOTE: We do NOT require request-level stopLoss/takeProfit anymore.
        // We allow them to be null and fall back to each trade's own SL/TP.

        // ==== SOQL (single) ====
        Trading_Account__c ta = [
            SELECT Id, MetaTrader_ID__c
            FROM Trading_Account__c
            WHERE Id = :reqIn.tradingAccountId
            LIMIT 1
        ];

        String mtAccountId = (ta != null && !String.isBlank(ta.MetaTrader_ID__c)) ? ta.MetaTrader_ID__c : null;
        if (mtAccountId == null) {
            res.success = false; res.message = 'MetaTrader_ID__c is null/blank on Trading_Account__c ' + String.valueOf(reqIn.tradingAccountId);
            return out;
        }

        // ==== Build endpoint (Named Credential) ====
        String base = 'callout:Atkex_Trading/api/position/accounts/';
        String path = EncodingUtil.urlEncode(mtAccountId, 'UTF-8') + '/positions/modify';
        String endpoint = base + path;

        if (!String.isBlank(reqIn.apiToken)) {
            endpoint += '?token=' + EncodingUtil.urlEncode(reqIn.apiToken, 'UTF-8');
        }
        res.effectiveEndpoint = endpoint != null ? endpoint.replace('callout:', '') : null;

        // ==== Build body with per-trade updates ====
        Map<String, Object> body = new Map<String, Object>();
        body.put('actionType', 'POSITION_MODIFY');

        // Clean + dedupe by position id from the DTO list
        // Also compute effective SL/TP for each trade using fallback rules
        Map<String, Map<String, Object>> dedupUpdatesById = new Map<String, Map<String, Object>>();
        Integer skippedNoValues = 0;

        for (OpenTradeDTO t : reqIn.openTrades) {
            if (t == null) continue;
            String pid = t.id != null ? t.id.trim() : null;
            if (String.isBlank(pid)) continue; // ignore invalid

            // Priority: request-level -> trade-level
            Decimal effSL = (reqIn.stopLoss != null) ? reqIn.stopLoss : t.stopLoss;
            Decimal effTP = (reqIn.takeProfit != null) ? reqIn.takeProfit : t.takeProfit;

            // If both null after fallbacks, skip this trade to avoid provider defaulting to 0
            if (effSL == null && effTP == null) {
                skippedNoValues++;
                continue;
            }

            Map<String, Object> u = new Map<String, Object>();
            u.put('positionId', pid);
            if (effSL != null) u.put('stopLoss', effSL);
            if (effTP != null) u.put('takeProfit', effTP);

            // If duplicate ids appear, last one wins
            dedupUpdatesById.put(pid, u);
        }

        List<Map<String, Object>> updates = new List<Map<String, Object>>();
        updates.addAll(dedupUpdatesById.values());

        if (updates.isEmpty()) {
            res.success = false;
            res.message = 'No effective updates: all trades missing SL/TP after fallback.';
            return out;
        }

        body.put('updates', updates);

        String jsonBody = JSON.serialize(body);
        System.debug('jsonBody: ' + jsonBody);

        // ==== Callout ====
        Http h = new Http();
        HttpRequest hreq = new HttpRequest();
        hreq.setMethod('POST');
        hreq.setEndpoint(endpoint);
        hreq.setHeader('Content-Type', 'application/json');
        hreq.setTimeout(120000);
        hreq.setBody(jsonBody);

        try {
            HttpResponse hres = h.send(hreq);
            res.statusCode   = (hres != null) ? hres.getStatusCode() : null;
            res.responseBody = (hres != null) ? hres.getBody()       : null;

            // Try to extract ok/fail counts if the Pi utility returns them
            // Expected shape: { results: [...], okCount: N, failCount: M }
            if (!String.isBlank(res.responseBody)) {
                try {
                    Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody);
                    if (parsed != null) {
                        Object ok = parsed.get('okCount');
                        Object fl = parsed.get('failCount');
                        res.okCount   = (ok instanceof Integer) ? (Integer)ok : (ok instanceof Long ? Integer.valueOf((Long)ok) : null);
                        res.failCount = (fl instanceof Integer) ? (Integer)fl : (fl instanceof Long ? Integer.valueOf((Long)fl) : null);
                    }
                } catch (Exception ignore) {
                    // leave ok/fail null if body not in expected shape
                }
            }

            Boolean is2xx = (res.statusCode != null && res.statusCode >= 200 && res.statusCode < 300);
            res.success = is2xx;

            // Surface info about any positions we intentionally skipped
            String skipMsg = (skippedNoValues > 0) ? ' (skipped ' + String.valueOf(skippedNoValues) + ' trade(s) with no SL/TP after fallback)' : '';

            res.message = is2xx
                ? 'Modify submitted.' + skipMsg
                : ('Modify failed: ' + (hres != null ? hres.getStatus() : 'No response'));

        } catch (System.CalloutException e) {
            res.success = false;
            res.message = 'Callout exception: ' + e.getMessage();
        } catch (Exception e) {
            res.success = false;
            res.message = 'Unexpected exception: ' + e.getMessage();
        }

        return out;
    }

}
