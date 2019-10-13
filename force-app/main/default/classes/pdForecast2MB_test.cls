@isTest(SeeAllData=true)
private class pdForecast2MB_test {
    @isTest
    private static void test_sendForecast() {
        Test.setMock(HttpCalloutMock.class, new pdForecast2MBCallMock());

        pdForecast2MB.sendForecast();
    }
}
