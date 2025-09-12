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