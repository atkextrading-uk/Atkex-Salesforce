public with sharing class StrategyIdService {

    @future(callout=true)
    public static void fetchAndSaveIds(Set<Id> strategyIds) {
        if (strategyIds == null || strategyIds.isEmpty()) return; // null-guard

        // Single SOQL outside loops
        List<Strategy__c> rows = [
            SELECT Id, External_Id__c
            FROM Strategy__c
            WHERE Id IN :strategyIds
        ];

        if (rows == null || rows.isEmpty()) return; // null-guard

        // Prepare HTTP client once
        Http http = new Http();

        // Collect updates here; do not DML in loop
        List<Strategy__c> toUpdate = new List<Strategy__c>();

        for (Strategy__c s : rows) {
            if (s == null) continue; // null-guard
            if (!String.isBlank(s.External_Id__c)) continue; // already has an id, skip

            try {
                HttpRequest req = new HttpRequest();
                // Named Credential: Atkex_Trading
                // Full endpoint becomes: https://api.atkextrading.uk + /api/strategy/new-id
                req.setEndpoint('callout:Atkex_Trading/api/strategy/new-id');
                req.setMethod('GET');
                req.setTimeout(15000);

                HttpResponse resp = http.send(req);

                Integer code = (resp == null) ? null : resp.getStatusCode();
                String body  = (resp == null) ? null : resp.getBody();

                if (code == null || code < 200 || code >= 300) {
                    System.debug(LoggingLevel.ERROR,
                        'StrategyIdService: non-2xx response for ' + s.Id +
                        ' status=' + String.valueOf(code) + ' body=' + body);
                    continue; // don’t block others
                }

                // Parse {"id":"H5sQ"}
                String newId;
                if (!String.isBlank(body)) {
                    try {
                        Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(body);
                        if (m != null && m.containsKey('id') && m.get('id') != null) {
                            newId = String.valueOf(m.get('id'));
                        }
                    } catch (Exception parseEx) {
                        System.debug(LoggingLevel.ERROR,
                            'StrategyIdService: JSON parse failed for ' + s.Id + ' err=' + parseEx.getMessage());
                    }
                }

                // Validate: CopyFactory needs exactly 4 alnum chars
                if (!String.isBlank(newId) && newId.length() == 4 && newId.replaceAll('[A-Za-z0-9]', '').length() == 0) {
                    Strategy__c upd = new Strategy__c(Id = s.Id, External_Id__c = newId);
                    toUpdate.add(upd);
                } else {
                    System.debug(LoggingLevel.WARN,
                        'StrategyIdService: invalid id returned for ' + s.Id + ': ' + String.valueOf(newId));
                }
            } catch (System.CalloutException e) {
                System.debug(LoggingLevel.ERROR,
                    'StrategyIdService: callout exception for ' + s.Id + ': ' + e.getMessage());
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR,
                    'StrategyIdService: unexpected exception for ' + s.Id + ': ' + e.getMessage());
            }
        }

        // Single bulk DML with try/catch
        if (!toUpdate.isEmpty()) {
            try {
                update toUpdate;
            } catch (DmlException dmle) {
                System.debug(LoggingLevel.ERROR,
                    'StrategyIdService: DML failed updating External_Id__c. Size='
                    + toUpdate.size() + ' err=' + dmle.getMessage());
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR,
                    'StrategyIdService: unexpected DML exception: ' + e.getMessage());
            }
        }
    }
}
