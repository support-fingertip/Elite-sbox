public class UnlockExpenseRecord {
    
    
    @future
    public static void unlockExpenses(Set<Id> expenseIds) {
        try {
            Approval.unlock(new List<Id>(expenseIds), false);
            System.debug('Unlocked expenses: ' + expenseIds);
        } catch (Exception e) {
            System.debug('Failed to unlock expenses: ' + e.getMessage());
        }
    }
}