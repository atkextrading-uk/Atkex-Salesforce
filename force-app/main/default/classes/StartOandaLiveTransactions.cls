public class StartOandaLiveTransactions {
    
    @InvocableMethod(label='Start Oanda live transations')
    public static void startOandaLiveTransactions(List<FlowInputs> fi) {      
        QueuableOandaLiveTransactions qClass = new QueuableOandaLiveTransactions(fi[0].recordId);
        Id batchId = System.enqueueJob(qClass);
        
    }

    public class FlowInputs {
        @InvocableVariable
        public Id recordId;
    }

}