global class DailyLogNotificationScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        // Call your main logic class
        DailyLogNotification.getEmployeesWithoutAttendence();
    }
    
}