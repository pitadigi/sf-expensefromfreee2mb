@isTest(SeeAllData=true)
private class pdExpenseFromFreee_test {
    @isTest
    static void getExpenseInfo_test() {
        Test.setMock(HttpCalloutMock.class, new pdExpenseFromFreeeCalloutMock());

        pdExpenseFromFreee.getExpenseInfo();
    }
}
