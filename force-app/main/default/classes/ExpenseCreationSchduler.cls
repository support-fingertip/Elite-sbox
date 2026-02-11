public class ExpenseCreationSchduler {
    public static void createExpenses() {
        /*Integer startDay = Integer.valueOf(Label.ExpenseStartDate); 
        Date today = Date.today();
        Date fromDate;
        Date toDate;
        boolean createExpense = true;
        
        if (createExpense) {
            system.debug('yes');
            fromDate = Date.newInstance(today.year(), today.month(), startDay);
            toDate = fromDate.addMonths(1).addDays(-1);
            system.debug('fromDate'+fromDate);
            system.debug('toDate'+toDate);
            
            List<User> userList = [SELECT Id, Name FROM User WHERE IsActive = true and Id ='005IR00000GESufYAH'];
            system.debug('userList'+userList);
            List<Expense__c> expensesList = new List<Expense__c>();
            string month = String.valueOf(toDate.month());
            string year =  String.valueOf(toDate.year());
            string MonthName  = getMonthName(month);
            for (User us : userList) {
                Expense__c expense = new Expense__c();
                expense.Expense_From_Date__c = fromDate;
                expense.Expense_To_Date__c = toDate;
                expense.Month__c = month;
                expense.Year__c = year;
                expense.Name = us.Name + ' / ' +MonthName+ ' ( '+ formatDate(fromDate) +' to '+ formatDate(toDate) +  ' ) '+' / '+ year;
                expense.OwnerId = us.Id;
                expensesList.add(expense);
            }
            
            // You can uncomment this when ready to insert
            insert expensesList;
        }*/
    }
    
    public static String formatDate(Date dt) {
        String[] months = new String[]{'January','February','March','April','May','June','July','August','September','October','November','December'};
            return dt.day() + ' ' + months[dt.month() - 1];
    }
    public static String getMonthName(string monthNumber) {
        String monthName = '';
        switch on monthNumber {
            when '1'{
                monthName = 'JAN';
            }
            when '2'{
                monthName = 'FEB';
            }
            when '3'{
                monthName = 'MARCH';
            }
            when '4'{
                monthName = 'APRIL';
            }
            when '5'{
                monthName = 'MAY';
            }
            when '6'{
                monthName = 'JUNE';
            }
            when '7'{
                monthName = 'JULY';
            }
            when '8'{
                monthName = 'AUG';
            }
            when '9'{
                monthName = 'SEPT';
            }
            when '10'{
                monthName = 'OCT';
            }
            when '11'{
                monthName = 'NOV';
            }
            when '12'{
                monthName = 'DEC';
            }
        }
        return monthName;
    }
}