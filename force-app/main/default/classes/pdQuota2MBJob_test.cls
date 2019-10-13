@isTest(SeeAllData=true)
class pdQuota2MBJob_test {
    static String CRON_EXP = '0 0 0 3 9 ? 2022';

    @isTest
    static void doTest() {
        Test.setMock(HttpCalloutMock.class, new pdQuota2MBCallMock());
        Test.startTest();

        String jobId = System.schedule('pdQuota2MBJob_test',
            CRON_EXP,
            new pdQuota2MBJob());

        Test.stopTest();
    }
}
