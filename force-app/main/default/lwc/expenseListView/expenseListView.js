import { LightningElement,track } from 'lwc';
import getExpenses from '@salesforce/apex/ExpenseListViewController.getExpenses';
import FORM_FACTOR from '@salesforce/client/formFactor';
import GOOGLE_ICONS from '@salesforce/resourceUrl/googleIcons';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import submitForApproval from '@salesforce/apex/ExpenseListViewController.submitForApproval';
import getExpensesbyFilter from '@salesforce/apex/ExpenseListViewController.getExpensesbyFilter';

export default class ExpenseListView extends LightningElement {
    isLoading = false;
    @track expenses = [];
    expnseHeader = ['Date','Allowance Type','Amount'];
    expenseListViewPage = true;
    expenseDetailePage = false;
    isDesktop = false;
    isPhone = false;
    recordId = '';
    @track comments = '';
    isDeleteModalOpen = false;
    isValidExpense = false;
    summeryIcons = {
            payment :  GOOGLE_ICONS + "/googleIcons/payment.png",
    };
    selectedEmployee = '';
    employeeOptions = [];

    selectedYear = '';
    yearOptions = [];

    selectedMonth = '';
    monthOptions = [];

    selectedStatus = '';
    statusOptions = [];
    isExpensesExisted = false;

    //on loading this method will be called
    connectedCallback() {
        this.isDesktop = FORM_FACTOR === 'Large'? true : false;
        this.isPhone = FORM_FACTOR === 'Small'? true : false;
        if(FORM_FACTOR === 'Medium')
        {
            this.isDesktop = true;
        }
        this.fetchexpenses();
        this.disablePullToRefresh();
    }
  
    // Fetching Expenses
    fetchexpenses() {
        this.isLoading = true;
        getExpenses({})
        .then((result) => {
            console.log('Expenses' + JSON.stringify(result));

            // Add expanded property and default class to each expense
            this.expenses = result.expenses
            .sort((a, b) => new Date(b.Expense_From_Date__c) - new Date(a.Expense_From_Date__c)) 
            .map(expense => ({
                ...expense,
                expanded: false,
                isNotSubmitted : expense.Approval_Status__c == 'Not Submitted'? true: false,
                isPending: (expense.Approval_Status__c == 'Pending' || 
                            expense.Approval_Status__c == 'Manager Approved') ? true: false,
                isApproved: expense.Approval_Status__c == 'Finance Dept. Approved'? true: false,
                isRejected:  (expense.Approval_Status__c == 'Finance Dept. Rejected' 
                             ||expense.Approval_Status__c == 'Manager Rejected') ? true: false,
                CustomClass: 'dropdown-body-pyt'
            }));
            this.isExpensesExisted  =    this.expenses.length > 0 ? true : false;
            this.employeeOptions = this.addAllOption(this.getPicklistValues(result.userList));
            this.yearOptions = this.addAllOption(result.years);
            this.monthOptions = this.addAllOption(result.months);
            this.statusOptions = this.addAllOption(result.approvalStatus);
            this.isLoading = false;
        })
        .catch((error) => {
            this.isLoading = false;
            this.showToast('Error', 'Error fetching expenses: ' + error.body.message, 'error');
        });
    }

    toggleDropdown(event) {
        const expenseId = event.currentTarget.dataset.id;
        this.expenses = this.expenses.map(expense => {
            if (expense.Id === expenseId) {  // Ensure correct property name
              
                
                return {
                    ...expense,
                    expanded: !expense.expanded, // Toggle current expense
                    CustomClass: !expense.expanded ? 'dropdown-body-pyt active' : 'dropdown-body-pyt'
                };
            } else {
                return {
                    ...expense,
                    expanded: false, // Close all others
                    CustomClass: 'dropdown-body-pyt'
                };
            }
        });
    }
    openExpenseDetailePage(event)
    {
        this.recordId = event.currentTarget.dataset.id;
        this.expenseDetailePage = true;
        this.expenseListViewPage = false;

    }
    goBackScreen(){
        this.expenseDetailePage = false;
        this.expenseListViewPage = true;
        this.fetchexpenses();
    }
    handleApprovalStatusChange(event) {
        this.isValidExpense = event.detail.isValid;
    }

    // Handle opening the modal
    openModal() {
        this.isDeleteModalOpen = true;
        let expenseContainer = this.template.querySelector('.expense-detailed-container');
        if (expenseContainer) {
            expenseContainer.classList.add('modal-blur');
        }
    }

    // Handle closing the modal
    handleDeleteCancel() {
        this.isDeleteModalOpen = false;
        this.comments = '';
        let expenseContainer = this.template.querySelector('.expense-detailed-container');
        if (expenseContainer) {
            expenseContainer.classList.remove('modal-blur');
        }
    }

    // Handle comments input change
    handleCommentsChange(event) {
        this.comments = event.target.value;
    }

    handleFilterChange(event) {
        const fieldName = event.target.name;
        const fieldValue  = event.detail.value;
        if(fieldName =='employee')
        {
            this.selectedEmployee = fieldValue;
        }
        else  if(fieldName =='year')
        {
            this.selectedYear  = fieldValue;
        }
        else  if(fieldName =='month')
        {
            this.selectedMonth = fieldValue;
        }
        else if(fieldName =='approvalStatus')
        {
            this.selectedStatus = fieldValue;
        }
        this.getFilteredExpenses();
    }
    getFilteredExpenses() {
        this.isLoading = true;
        getExpensesbyFilter({
            userId: this.selectedEmployee,
            year: this.selectedYear,
            month: this.selectedMonth,
            approvalStatus: this.selectedStatus
        })
        .then(result => {
            this.expenses = result
            .sort((a, b) => new Date(b.Expense_From_Date__c) - new Date(a.Expense_From_Date__c))
            .map(expense => ({
               ...expense,
                expanded: false,
                isNotSubmitted : expense.Approval_Status__c == 'Not Submitted'? true: false,
                isPending: (expense.Approval_Status__c == 'Pending' || 
                            expense.Approval_Status__c == 'Manager Approved') ? true: false,
                isApproved: expense.Approval_Status__c == 'Finance Dept. Approved'? true: false,
                isRejected:  (expense.Approval_Status__c == 'Finance Dept. Rejected' 
                             ||expense.Approval_Status__c == 'Manager Rejected') ? true: false,
                CustomClass: 'dropdown-body-pyt'
            }));
            this.isExpensesExisted  =    this.expenses.length > 0 ? true : false;
            this.isLoading = false;
        })
        .catch(error => {
            console.error('Error fetching expenses:', error);
        });
    }

   
    handleStatusChange(event) {
        this.selectedStatus = event.detail.value;
    }

    // Handle submit action
    handleSubmit() {
          // Validations
        if (!this.comments) {
            this.showToast('Error', 'Please enter comments', 'error');
            return;
        }
        this.isDeleteModalOpen = false;
        submitForApproval({ recordId: this.recordId, comments: this.comments })
        .then(() => {
            // Handle success (e.g., show a toast message)
          
            const expensePage = this.template.querySelector('c-expense-detailed-page');
            if (expensePage) {
                expensePage.refreshData();
            }
            this.isValidExpense = false;
            this.comments = '';
            let expenseContainer = this.template.querySelector('.expense-detailed-container');
            if (expenseContainer) {
                expenseContainer.classList.remove('modal-blur');
            }
            this.showToast('Success', 'Expense has been successfully submitted for approval.', 'success');
              // Call the refresh method in the child component
           
        })
        .catch(error => {
            // Handle error (e.g., show a toast message)
            console.error('Error submitting for approval:', error);

        });
    }
    addAllOption(options) {
        return [{ label: 'Select an Option', value: '' }, ...options];
    }
    getPicklistValues(optionsArray) { 
        return optionsArray.map(option => ({ label: option.Name, value: option.Id })); 
    }
    showToast(title, message, variant) {
            this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
    disablePullToRefresh() {
        const disableRefresh = new CustomEvent("updateScrollSettings", {
          detail: {
            isPullToRefreshEnabled: false
          },
          bubbles: true,
          composed: true
        });
        this.dispatchEvent(disableRefresh);
    }
}