public class EmployeeReplacementUpdateQueue implements Queueable {
    private List<Employee__c> employeesToUpdate;

    public EmployeeReplacementUpdateQueue(List<Employee__c> employees) {
        this.employeesToUpdate = employees;
    }

    public void execute(QueueableContext context) {
        try {
            if (employeesToUpdate != null && !employeesToUpdate.isEmpty()) {
                update employeesToUpdate;
            }
        } catch (Exception ex) {
            System.debug('Error updating employees in Queueable: ' + ex.getMessage());
        }
    }
}