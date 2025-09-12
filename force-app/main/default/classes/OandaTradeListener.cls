@RestResource(urlMapping='/oanda_webhook/gold_scalp')
global class OandaTradeListener {

    @HttpPost
    global static void tradeSignal() {
        RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString();

        System.debug('Test Req | ' + requestBody);
    }
}