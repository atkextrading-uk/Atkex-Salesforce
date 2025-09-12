public class QueuableOandaLiveTransactions implements System.Queueable, Database.AllowsCallouts {
    public Id accId;

    public List<RESTResponse.cls_transactions> transactions = new List<RESTResponse.cls_transactions>();

    //public HttpResponse response = null;


    public QueuableOandaLiveTransactions(Id acc) {
        this.accId = acc;
        //response = new HttpResponse();
    }

    /*
    @future(callout = true)
    public static void makeCallout(String accId, Decimal lastId, String oandaId) {
        String apiKey = oandaId;
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        String apiUrl = 'https://api-fxtrade.oanda.com/v3/accounts/' + accId + '/transactions/sinceid?id=' + lastId;
        req.setEndpoint(apiUrl);
 
        req.setMethod('GET');
        Map<String, String> headers = new Map<String, String>{
            'Authorization' => 'Bearer ' + apiKey
        };
        req.setHeader('Authorization', 'Bearer ' + apiKey);
        HttpResponse res = h.send(req);
        this.response = res;
    }*/

    
    public void execute(QueueableContext context) {
        Account acc = [SELECT ID, Oanda_Account_Id__c, Oanda_Connection__c, Oanda__c, Oanda_Latest_Ticket_Number__c
            FROM Account
            WHERE Id = :this.accId];

        String apiKey = acc.Oanda__c;

        Http h = new Http();
        HttpRequest req = new HttpRequest();
        String apiUrl = 'https://api-fxtrade.oanda.com/v3/accounts/' + acc.Oanda_Account_Id__c + '/transactions/sinceid?id='+acc.Oanda_Latest_Ticket_Number__c;
        req.setEndpoint(apiUrl);
 
        req.setMethod('GET');
        Map<String, String> headers = new Map<String, String>{
            'Authorization' => 'Bearer ' + apiKey
        };
        req.setHeader('Authorization', 'Bearer ' + apiKey);
        HttpResponse res = h.send(req);
        //makeCallout(acc.Oanda_Account_Id__c, acc.Oanda_Latest_Ticket_Number__c, acc.Oanda__c);

        // while(this.response == null) {
        //     System.debug('Awaiting response');
        // }

        //List<String> pages = new List<String>();
         
        if (res.getStatusCode() == 200) {
            String jsonString = res.getBody().replace('time', 'transactionTime');

            RESTResponse.OandaTransactionsPage oandaTransactionsPage = (RESTResponse.OandaTransactionsPage) JSON.deserialize(jsonString, RESTResponse.OandaTransactionsPage.class);
            transactions = (List<RESTResponse.cls_transactions>) oandaTransactionsPage.transactions;
            for (RESTResponse.cls_transactions tt : transactions) {
                System.debug(tt);
            }
            
        }


        if (acc.Oanda_Connection__c == 'Active') {
            datetime start = System.now();
            while(System.now() < start.addSeconds(5)) {}

            QueuableOandaLiveTransactions qClass = new QueuableOandaLiveTransactions(this.accId);
            Id batchId = System.enqueueJob(qClass);

            /*Datetime now = Datetime.now();
            Datetime scheduledTime = now.addSeconds(10);
            
            String cronExpression = '0 ' + scheduledTime.minute() + ' ' + scheduledTime.hour() + ' ' + scheduledTime.day() + ' ' + scheduledTime.month() + ' ? ' + scheduledTime.year();
            
            System.enqueueJob('Delayed Job', cronExpression, qClass);*/
        }
    }
}