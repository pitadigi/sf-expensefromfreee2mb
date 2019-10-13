global class pdQuota2MBJob implements Schedulable {
    global void execute(SchedulableContext ctx) {
        pdQuota2MB.sendQuota();
    }
}
