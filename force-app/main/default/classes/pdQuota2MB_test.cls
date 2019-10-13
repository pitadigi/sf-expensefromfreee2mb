@isTest(SeeAllData=true)
private class pdQuota2MB_test {
    @isTest
    private static void test_sendQuota() {
        Test.setMock(HttpCalloutMock.class, new pdQuota2MBCallMock());

        pdQuota2MB.sendQuota();
    }
}
