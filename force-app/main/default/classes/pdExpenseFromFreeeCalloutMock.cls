global class pdExpenseFromFreeeCalloutMock implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        String endPoint = req.getEndpoint();
        HttpResponse res = new HttpResponse();
        if(endPoint == 'callout:Freee/companies') {
            res.setStatusCode(200);
            String body = '{"companies": [{"id": 1,"name": "ぴたデジ株式会社"}]}';
            res.setBody(body);
        }
        else if(endPoint.indexOf('callout:Freee/account_items') != (-1)) {
            res.setStatusCode(200);
            String body = '{"account_items": [{"id": 1,"name": "支払手数料"}]}';
            res.setBody(body);
        }
        else if(endPoint.indexOf('callout:Freee/deals') != (-1)) {
            res.setStatusCode(200);
            String body = '{"deals": [{"issue_date": "2019-10-01","details":[{"id": 1,"account_item_id": 1,"amount": 5250,"description": "備考"}]}]}';
            res.setBody(body);
        }
        else if(endPoint.indexOf('https://cloud-up.motionboard.jp') != (-1)) {
            res.setStatusCode(200);
        }

        return res;
    }
}
