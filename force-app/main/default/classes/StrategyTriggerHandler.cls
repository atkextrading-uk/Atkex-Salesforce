public with sharing class StrategyTriggerHandler {

    public class TriggerWrapper {
        public List<Strategy__c> oldList;
        public List<Strategy__c> newList;
        public Map<Id, Strategy__c> oldMap;
        public Map<Id, Strategy__c> newMap;
        public TriggerWrapper(List<Strategy__c> oldList,
                              List<Strategy__c> newList,
                              Map<Id, Strategy__c> oldMap,
                              Map<Id, Strategy__c> newMap) {
            this.oldList = (oldList == null) ? new List<Strategy__c>() : oldList;
            this.newList = (newList == null) ? new List<Strategy__c>() : newList;
            this.oldMap  = (oldMap  == null) ? new Map<Id, Strategy__c>() : oldMap;
            this.newMap  = (newMap  == null) ? new Map<Id, Strategy__c>() : newMap;
        }
    }

    public static void run(TriggerWrapper tw) {
        if (tw == null) return; // null-guard

        if (Trigger.isBefore) {
            if (Trigger.isInsert) beforeInsert(tw);
            if (Trigger.isUpdate) beforeUpdate(tw);
        } else if (Trigger.isAfter) {
            if (Trigger.isInsert) afterInsert(tw);
        }
    }

    // You can use this to normalize/validate incoming records if needed
    private static void beforeInsert(TriggerWrapper tw) {
        if (tw == null || tw.newList == null) return; // null-guard
        // Intentionally no DML here.
        // If External_Id__c is already provided, we leave it untouched.
    }

    private static void beforeUpdate(TriggerWrapper tw) {
        if (tw == null || tw.newList == null) return; // null-guard
        // Keep lean; no SOQL/DML in loops.
    }

    // After insert we asynchronously fetch a new id (if External_Id__c is blank) and update in bulk
    private static void afterInsert(TriggerWrapper tw) {
        if (tw == null || tw.newList == null) return; // null-guard

        Set<Id> needsId = new Set<Id>();
        for (Strategy__c s : tw.newList) {
            if (s == null) continue; // null-guard
            if (String.isBlank((String)s.get('External_Id__c'))) {
                needsId.add(s.Id);
            }
        }
        if (!needsId.isEmpty()) {
            // Use @future callout to fetch and save ids
            StrategyIdService.fetchAndSaveIds(needsId);
        }
    }
}