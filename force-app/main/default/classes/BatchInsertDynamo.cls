global class BatchInsertDynamo implements Database.Batchable<SObject>, Database.Stateful {
    List<Oanda_Trade__x> listTrades = new List<Oanda_Trade__x>();
    global BatchInsertDynamo(List<Oanda_Trade__x> lt) {
        listTrades = lt;
    }
    // QueryLocator to retrieve the records to be processed
    global Iterable<SObject> start(Database.BatchableContext BC) {
        return listTrades;
    }

    // This method is called for each batch of records
	global void execute(Database.BatchableContext BC, List<SObject> scope) {
        try {
            Database.insertImmediate(scope);
        } catch (DmlException e) {
            // Handle the exception, log the error, or take corrective action
            System.debug('Error inserting records: ' + e.getMessage());
            
            // Optionally, retry failed records individually
            for (SObject record : scope) {
                try {
                    Database.insertImmediate(record);
                } catch (DmlException singleError) {
                    System.debug('Failed to insert record: ' + singleError.getMessage());
                    // Log or handle the individual record failure
                }
            }
        }
    }

    global void finish(Database.BatchableContext BC) {
        System.debug('Batch processing completed.');
        
    }
}

/**
 * Archived_Trade__x at = new Archived_Trade__x();
at.UUID__c = 'test';
at.Trading_Account__c = 'a0GJ7000003nKAzMAM';
at.ExternalId = 'test123';

// If Trading_Account__c is an Indirect Lookup, set it to the parent's *external id* value
// e.g., Account acct = [SELECT External_Ref__c FROM Account WHERE Id = :someId];
// at.Trading_Account__c = acct.External_Ref__c;

Database.SaveResult sr = Database.insertImmediate(at);
if (!sr.isSuccess()) {
    for (Database.Error e : sr.getErrors()) {
        System.debug('Status: ' + e.getStatusCode() + ' | ' + e.getMessage());
        if (e.getFields() != null) System.debug('Fields: ' + e.getFields());
    }
} else {
    System.debug('Inserted. ExternalId returned: ' + sr.getId());
}
 */