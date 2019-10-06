global class pdExpenseFromFreeeCalloutMock implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        String endPoint = req.getEndpoint();
        HttpResponse res = new HttpResponse();
        if(endPoint == 'callout:Freee/account_item') {
            res.setStatusCode(200);
            String body = '{"account_items": [{"id": 1,"name": "支払手数料"}]}';
            res.setBody(body);
        }

        return res;
    }
}
