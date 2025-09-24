public with sharing class SubscriberSyncService {

    public class Result {
        @AuraEnabled public Id     subscriberId;
        @AuraEnabled public Boolean success;
        @AuraEnabled public Integer statusCode;
        @AuraEnabled public String  message;
        @AuraEnabled public String  responseBody;
        @AuraEnabled public String  effectiveEndpoint;
    }

    /**
     * Bulk-safe service method. Does ONE SOQL to verify records exist,
     * no DML inside loops, and try/catch around DML.
     *
     * @param subscriberIds List of Subscriber__c Ids to push to CopyFactory (via Raspberry Pi).
     * @return Results per Subscriber__c
     */
    @AuraEnabled
    public static List<Result> applySubscribersToCopyFactory(List<Id> subscriberIds) {
        List<Result> results = new List<Result>();

        // Null guards
        if (subscriberIds == null || subscriberIds.isEmpty()) {
            Result r = new Result();
            r.success = false;
            r.message = 'No Subscriber__c Ids provided.';
            r.statusCode = 400;
            results.add(r);
            return results;
        }

        // MASS retrieval BEFORE any loops
        Map<Id, Subscriber__c> subsById = new Map<Id, Subscriber__c>();
        try {
            // Only the Id is required for the callout URL; we fetch minimally and in bulk.
            // (Adjust fields if you later want to record status back to the record.)
            for (Subscriber__c s : [
                SELECT Id
                FROM Subscriber__c
                WHERE Id IN :subscriberIds
            ]) {
                subsById.put(s.Id, s);
            }
        } catch (Exception soqlEx) {
            // Defensive: SOQL error surfaced as a single result
            Result r = new Result();
            r.success = false;
            r.message = 'SOQL failed while loading Subscriber__c records: ' + soqlEx.getMessage();
            r.statusCode = 500;
            results.add(r);
            return results;
        }

        // Prepare base endpoint (Named Credential)
        // Effective URL will look like: callout:Atkex_API/api/meta/subscribers/apply/{Id}
        String base = 'callout:Atkex_Trading'  + '/api/subscriber/apply/';

        // We’ll collect optional write-backs (if you add such fields) and do ONE DML after loop
        List<Subscriber__c> toUpdate = new List<Subscriber__c>();

        for (Id subId : subscriberIds) {
            Result r = new Result();
            r.subscriberId = subId;
            r.success = false; // default to false; set true on success

            Subscriber__c rec = subsById.get(subId);
            if (rec == null) {
                r.statusCode = 404;
                r.message = 'Subscriber__c not found: ' + String.valueOf(subId);
                results.add(r);
                continue;
            }

            try {
                HttpRequest req = new HttpRequest();
                req.setMethod('PUT');
                req.setEndpoint(base + EncodingUtil.urlEncode((String)subId, 'UTF-8'));
                req.setTimeout(20000);

                // No body required; Pi route derives everything from SF
                // req.setBody('{}');

                Http http = new Http();
                HTTPResponse resp = http.send(req);

                r.statusCode = resp != null ? resp.getStatusCode() : 0;
                r.responseBody = resp != null ? resp.getBody() : null;
                r.effectiveEndpoint = req.getEndpoint();

                if (r.statusCode >= 200 && r.statusCode < 300) {
                    r.success = true;
                    r.message = 'Subscriber pushed to CopyFactory.';
                    // Optional: set write-back fields on rec, e.g. status + timestamp
                    // rec.CopyFactory_Sync_Status__c  = 'Success';
                    // rec.CopyFactory_Sync_Message__c = 'OK';
                    // rec.CopyFactory_Last_Sync__c    = System.now();
                    // toUpdate.add(rec);
                } else {
                    r.message = 'Upstream error from Pi/CopyFactory. See responseBody.';
                    // Optional failure write-back
                    // rec.CopyFactory_Sync_Status__c  = 'Failed';
                    // rec.CopyFactory_Sync_Message__c = r.responseBody;
                    // rec.CopyFactory_Last_Sync__c    = System.now();
                    // toUpdate.add(rec);
                }
            } catch (System.CalloutException calloutEx) {
                r.statusCode = 500;
                r.message = 'Callout failed: ' + calloutEx.getMessage();
                r.effectiveEndpoint = base + String.valueOf(subId);
                // Optional failure write-back
                // rec.CopyFactory_Sync_Status__c  = 'Failed';
                // rec.CopyFactory_Sync_Message__c = r.message;
                // rec.CopyFactory_Last_Sync__c    = System.now();
                // toUpdate.add(rec);
            } catch (Exception ex) {
                r.statusCode = 500;
                r.message = 'Unexpected error: ' + ex.getMessage();
                r.effectiveEndpoint = base + String.valueOf(subId);
                // Optional failure write-back
                // rec.CopyFactory_Sync_Status__c  = 'Failed';
                // rec.CopyFactory_Sync_Message__c = r.message;
                // rec.CopyFactory_Last_Sync__c    = System.now();
                // toUpdate.add(rec);
            }

            results.add(r);
        }

        // Single DML outside loop (if you decided to write back fields)
        if (!toUpdate.isEmpty()) {
            try {
                update toUpdate;
            } catch (DmlException dmlEx) {
                System.debug(LoggingLevel.ERROR, 'DML update failed in SubscriberSyncService.applySubscribersToCopyFactory: ' + dmlEx.getMessage());
                // We don’t hard-fail the entire operation; results already contain per-record statuses
            }
        }

        return results;
    }
}
