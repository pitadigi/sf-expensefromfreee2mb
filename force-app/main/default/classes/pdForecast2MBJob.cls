global class pdForecast2MBJob implements Schedulable {
    global void execute(SchedulableContext ctx) {
        pdForecast2MB.sendForecast();
    }
}
