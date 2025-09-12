@RestResource(urlMapping='/trade/transaction')
global class REST_TradeTransaction {

    /*@HttpGet
    global static void doGet() {
        // Implement your logic to handle GET requests here
        RestResponse response = RestContext.response;
        response.addHeader('Content-Type', 'application/json');
        response.responseBody = Blob.valueOf('{"message": "Hello, Salesforce RESTful API!"}');
    }*/

    @HttpPost
    global static void doPost() {
        // Implement your logic to handle POST requests here
        RestRequest request = RestContext.request;
        //RestResponse response = RestContext.response;
        //response.addHeader('Content-Type', 'application/json');

        // Read the request body
        String requestBody = request.requestBody.toString();
        // Process the request body and perform any actions accordingly
        System.debug(requestBody);

        String jsonString = requestBody.replace('time', 'transactionTime');

        RESTResponse.cls_transactions tr = (RESTResponse.cls_transactions) JSON.deserialize(jsonString, RESTResponse.cls_transactions.class);

        OandaUtility.updateTransation(tr);

        // Create a JSON response
        //String jsonResponse = '{"message": "Received POST request."}';
        //response.responseBody = Blob.valueOf(jsonResponse);
    }
}