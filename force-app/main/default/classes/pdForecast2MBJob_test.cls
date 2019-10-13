@isTest(SeeAllData=true)
class pdForecast2MBJob_test {
    static String CRON_EXP = '0 0 0 3 9 ? 2022';
    
    @isTest
    static void doTest() {
        Test.setMock(HttpCalloutMock.class, new pdForecast2MBCallMock());
        Test.startTest();

        String jobId = System.schedule('pdForecast2MBJob_test',
            CRON_EXP,
            new pdForecast2MBJob());

        Test.stopTest();
    }
}
