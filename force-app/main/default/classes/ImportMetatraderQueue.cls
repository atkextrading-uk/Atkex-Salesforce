public with sharing class ImportMetatraderQueue implements Queueable, Database.AllowsCallouts {

    private final List<Id> taIds;

    public ImportMetatraderQueue(List<Id> taIds) {
        this.taIds = (taIds == null) ? new List<Id>() : new List<Id>(taIds);
    }

    public void execute(QueueableContext qc) {
        if (taIds.isEmpty()) return;

        // Decide which action to run based on the current minute
        Integer minute = Datetime.now().minute();
        Boolean doTradeImport   = Math.mod(minute, 10) == 0; // 0,10,20,30,40,50
        Boolean doBalanceUpdate = Math.mod(minute, 10) == 5; // 5,15,25,35,45,55

        // If you only schedule every 5 minutes, one of these will always be true.
        if (!doTradeImport && !doBalanceUpdate) {
            // Not on a 5-minute boundary – nothing to do.
            return;
        }

        for (Id taId : taIds) {
            if (taId == null) continue;

            try {
                if (doTradeImport) {
                    // Import trades for this Trading Account
                    ImportMetatraderTradesByAccount.run(new List<Id>{ taId });
                }
                if (doBalanceUpdate) {
                    // Update the account details/balance for this Trading Account
                    UpdateMetatraderAccountDetails.run(new List<Id>{ taId });
                }

            } catch (Exception ex) {
                System.debug(LoggingLevel.ERROR,
                    'Import/Update failed for Trading_Account__c ' + String.valueOf(taId) +
                    ' — ' + ex.getMessage());
            }
        }
    }
}
