public class CloseTradeAfterDelay implements Schedulable, Database.AllowsCallouts {
    private String tradeId;
    private String accountId;

    public CloseTradeAfterDelay(String tradeId, String accountId) {
        this.tradeId = tradeId;
        this.accountId = accountId;
    }

    public void execute(SchedulableContext context) {
        futureCallout('https://api-fxpractice.oanda.com/v3/accounts/' + accountId + '/trades/' + tradeId + '/close');
    }

    @future(callout=true)
    public static void futureCallout(String ep) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(ep);
        req.setHeader('Authorization', 'Bearer 1f1befaad5d67687ff7e0aa2eb10eac7-d09b57596e582795520209741fc897f8');
        req.setMethod('PUT');
        req.setHeader('Content-Type', 'application/json');

        Http http = new Http();
        HTTPResponse res = http.send(req);

        System.debug('Close trade response: ' + res.getBody());
    }
}