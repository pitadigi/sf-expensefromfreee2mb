global with sharing class pdForecast2MBCallMock implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        String endPoint = req.getEndpoint();
        HttpResponse res = new HttpResponse();
        if(endPoint.indexOf('https://cloud-up.motionboard.jp') != (-1)) {
            res.setStatusCode(200);
        }

        return res;
    }
}
