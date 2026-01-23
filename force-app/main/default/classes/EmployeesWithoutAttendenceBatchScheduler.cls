global class EmployeesWithoutAttendenceBatchScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        // Call your main logic class
        EmployeesWithoutAttendenceBatch bt = new EmployeesWithoutAttendenceBatch();
        database.executeBatch(bt,1);
    }
    
}