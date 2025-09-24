public with sharing class ApplySubscriberToCopyFactory {
    public class Request {
        @InvocableVariable(required=true)
        public Id subscriberId;
    }

    public class Response {
        @InvocableVariable public Id     subscriberId;
        @InvocableVariable public Boolean success;
        @InvocableVariable public Integer statusCode;
        @InvocableVariable public String  message;
        @InvocableVariable public String  responseBody;
        @InvocableVariable public String  effectiveEndpoint;
    }

    @InvocableMethod(label='Apply Subscriber to CopyFactory'
                     description='Calls Raspberry Pi to push a Subscriber__c to CopyFactory using its related MetaApi account id'
                     callout=true)
    public static List<Response> run(List<Request> requests) {
        // Null guard
        if (requests == null || requests.isEmpty()) {
            Response r = new Response();
            r.success = false;
            r.message = 'No requests provided.';
            return new List<Response>{ r };
        }

        // If you want to allow per-run token override:
        // Temporarily stash override into a custom setting or a Platform Cache if needed by the service.
        // For simplicity, this sample keeps token handling in Named Credential / Service.Settings.

        // Mass prepare input Ids (no SOQL/DML in loop)
        List<Id> ids = new List<Id>();
        for (Request req : requests) {
            if (req == null || req.subscriberId == null) continue; // null guards
            ids.add(req.subscriberId);
        }

        // Delegate to the service
        List<SubscriberSyncService.Result> svcRes = SubscriberSyncService.applySubscribersToCopyFactory(ids);

        // Map to invocable Response
        List<Response> out = new List<Response>();
        for (SubscriberSyncService.Result r : svcRes) {
            Response rr = new Response();
            rr.subscriberId      = r != null ? r.subscriberId : null;
            rr.success           = r != null ? r.success : false;
            rr.statusCode        = r != null ? r.statusCode : 0;
            rr.message           = r != null ? r.message : 'No response';
            rr.responseBody      = r != null ? r.responseBody : null;
            rr.effectiveEndpoint = r != null ? r.effectiveEndpoint : null;
            out.add(rr);
        }
        return out;
    }
}
