import { LightningElement, api, track, wire } from 'lwc';
import getExpenseLineItems from '@salesforce/apex/ExpenseApprovalController.getExpenseLineItems';
import getExpenseDetails from '@salesforce/apex/ExpenseApprovalController.getExpenseDetails';
import updateExpenseLineItems from '@salesforce/apex/ExpenseApprovalController.updateExpenseLineItems';
import approveExpenseItems from '@salesforce/apex/ExpenseApprovalController.approveExpenseItems';
import rejectExpenses from '@salesforce/apex/ExpenseApprovalController.rejectExpenses';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import USER_ID from '@salesforce/user/Id';
import { NavigationMixin } from 'lightning/navigation';

export default class ExpenseApproveUI extends NavigationMixin(LightningElement)  {
    @api recordId;
    @track data = [];
    @track selectedRows = [];
    @track draftValues = [];
    @track showSaveButton = false;
    @track hasSelectableRows= false;
    wiredDataResult;
    expenseTitle = 'Expense Approval';
    currentUserId = USER_ID;
    isOpenedByOwner = false;
    existingExpense ={};
    approvalComments = '';
    isOpenedByAdmin = false;
    isAllSelected = false;
    isLoading = false;

    expenseApprovers = { L1: null, L2: null, Finance: null };

    get isLoading() {
        return !this.wiredDataResult?.data && !this.wiredDataResult?.error;
    }
    handleRefresh() {
        Promise.all([
            refreshApex(this.wiredExpenseResult),
            refreshApex(this.wiredDataResult)
        ])
        .then(() => {
            // Optionally show toast or spinner stop
            console.log('Expense details and line items refreshed');
        })
        .catch(error => {
            console.error('Error refreshing data:', error);
        });
    }

 
    
    // Wire expense approver info
    @wire(getExpenseDetails, { expenseId: '$recordId' })
    wiredExpense({ data, error }) {
        if (data) {
            this.isOpenedByOwner = data.isOpenedByAdmin == true ? false : data.isOpenedByOwner;
            this.isOpenedByAdmin = data.isOpenedByAdmin;
            this.expenseApprovers = {
                L1: data.expense.Expense_Approver_L1__c,
                L2: data.expense.Expense_Approver_L2__c,
                Finance: data.expense.Expense_Finance_Department_Approver__c
            };
        } else if (error) {
            console.error('Expense detail error', error);
        }
    }

    // Wire expense line items
    @wire(getExpenseLineItems, { recordId: '$recordId' })
    wiredExpenseLineItems(result) {
        this.wiredDataResult = result;
        const { data, error } = result;
        if (data) {
            this.hasSelectableRows = false;
            //this.data = data.map(row => this.processRow(row));
            // Define the custom order mapping
            const expenseTypeOrder = {
                'TA': 1,
                'DA': 2,
                'Food': 3,
                'Lodging': 4,
                'Lodging + Food': 5,
                'Local Conveyance': 6,
                'Courier Charges': 7,
                'Mobile Charges': 8,
                'Transport Conveyance': 9,
                'Other/MISC': 10
            };

            // Process and sort data
            this.data = data
            .map(row => this.processRow(row))
            .sort((a, b) => {

                // Sort by expDate (descending)
                const dateA = new Date(a.expDate);
                const dateB = new Date(b.expDate);
                if (dateA.getTime() !== dateB.getTime()) {
                    return  dateA - dateB; // latest first
                }

                // Sort by expType (descending based on custom order)
                const orderA = expenseTypeOrder[a.expType] || 999;
                const orderB = expenseTypeOrder[b.expType] || 999;
                return orderA - orderB ; // highest order first
            });


        } else if (error) {
            console.error('Error loading expense lines:', error);
        }
    }

    processRow(row) {
        let editable = false;
        let selectable = false;
       
        const status = row.status;
        const type = row.expType;
        const l1 = this.expenseApprovers.L1;
        const l2 = this.expenseApprovers.L2;
        const finance = this.expenseApprovers.Finance;
        const user = this.currentUserId;
        if (user === l1 && status === 'Pending') {
            if (type !== 'TA') editable = true;
            selectable = true;
        }else if ((user === finance && status === 'Level 1 Approved') || (!l1 && (user === finance && status === 'Pending'))) {
            editable = true;
            selectable = true;
        }
        else if(this.isOpenedByAdmin &&  (status=='Pending' ||  status === 'Level 1 Approved'))
        {
            if (type !== 'TA') editable = true;
            selectable = true;
        }


        if(selectable == true){
            this.hasSelectableRows=true;
        }


        const dateStr = row.expDate;
        let dateStrIndia = '';
        if (dateStr) {
            const parts = dateStr.split('-');
            dateStrIndia = `${parts[2]}-${parts[1]}-${parts[0]}`;
        }


        // Attachments
        let filesArray = [];
        if (row.files && row.files.length > 0) {
            filesArray = row.files.map(f => {
                let downloadUrl;
                if (f.fileType === 'PDF') {
                    // PDFs: download
                    downloadUrl = `/sfc/servlet.shepherd/version/download/${f.latestVersionId}`;
                } else {
                    // Images / other: open in new tab
                    downloadUrl = `/sfc/servlet.shepherd/version/renditionDownload?rendition=THUMB720BY480&versionId=${f.latestVersionId}`;
                }
                return {
                    id: f.contentDocumentId,
                    title: f.title,
                    downloadUrl: downloadUrl,
                    isPdf: f.fileType === 'PDF'
                };
            });
        }
        return {
            ...row,
            expDate: dateStr,
            expDateFormatted :  dateStrIndia,
            isEditable: editable,
            isSelectable: selectable,
            isChecked : false,
            files: filesArray,
            highlightClass: selectable ? 'highlight-row' : ''
        };
    }

    handleSelectAll(event) {
        const isChecked = event.target.checked;
        this.isAllSelected = isChecked;

        // Select all eligible rows
        this.data.forEach(row => {
            if (row.isSelectable) {
                row.isChecked = isChecked;
            }
        });

        // Update the list of selected record Ids
        if (isChecked) {
            this.selectedRows = this.data
                .filter(row => row.isSelectable)
                .map(row => row.recordId);
        } else {
            this.selectedRows = [];
        }

        // Reflect checkbox states in the UI
        this.template.querySelectorAll('lightning-input[type="checkbox"]').forEach(input => {
            if (input.dataset.id) {
                input.checked = isChecked;
            }
        });
    }


    handleAmountChange(event) {
        const recId = event.target.dataset.id;
        const newValue = parseFloat(event.target.value);
        const found = this.data.find(d => d.recordId === recId);
        if (found) found.amount = newValue;
    }

    handleRowSelection(event) {
        const recId = event.target.dataset.id;
        if (event.target.checked) {
            if (!this.selectedRows.includes(recId)) this.selectedRows.push(recId);
        } else {
            this.selectedRows = this.selectedRows.filter(id => id !== recId);
        }
    }
    
    
    handleSave() {
        if (!this.draftValues.length) return;
        const updatedExpenses = this.draftValues.map(d => {
            return {
                Id: d.recordId,
                Amount__c: d.amount
            };
        });
        updateExpenseLineItems({ updatedExpenses })
        .then(() => {
            this.showToast('Success', 'Expenses updated successfully.', 'success');
            this.draftValues = [];
            this.showSaveButton = false;
            this.isAllSelected = false;
            return refreshApex(this.wiredDataResult);
        })
        .catch(error => {
            this.showToast('Error', error.body?.message || error.message, 'error');
        });
    }

    handleAmountChange(event) {
    const recId = event.target.dataset.id;
    const newValue = parseFloat(event.target.value);

    // Update data
    const found = this.data.find(d => d.recordId === recId);
    if (found) {
        found.amount = newValue;
    }

    // Track draft changes
    const existingDraft = this.draftValues.find(d => d.recordId === recId);
    if (existingDraft) {
        existingDraft.amount = newValue;
    } else {
        this.draftValues.push({ recordId: recId, amount: newValue });
    }

    this.showSaveButton = this.draftValues.length > 0;
    }
    previewFile(event) {
        if (!navigator.onLine) {
            this.showToast('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        let recordId = event.currentTarget.dataset.id;
        console.log('recordId'+recordId);
        //  const filetype = event.currentTarget.id
          this[NavigationMixin.Navigate]({
              type: 'standard__namedPage',
              attributes: {
                  pageName: 'filePreview'
              },
              state: {
                  selectedRecordId: recordId
              }
          });


    }


    handleApprove() {
        if (this.selectedRows.length === 0) {
            this.showToast('No rows selected', 'Please select at least one row to approve.', 'warning');
            return;
        }
        console.log('this.approvalComments '+this.approvalComments );
        approveExpenseItems({ expenseIds: this.selectedRows,expId: this.recordId,approvalComments : this.approvalComments })
        .then(() => {
            this.showToast('Success', 'Selected expenses approved successfully.', 'success');
            this.selectedRows = [];
            this.approvalComments ='';
            this.isAllSelected = false;
            return refreshApex(this.wiredDataResult);
        })
        .catch(err => {
            this.showToast('Error', err.body?.message || err.message, 'error');
        });
    }
    

    async handleReject() {
        if (this.selectedRows.length === 0) {
            this.showToast('No rows selected', 'Please select at least one row to reject.', 'warning');
            return;
        }
        try {
            await rejectExpenses({ expenseIds: this.selectedRows,expId: this.recordId,approvalComments : this.approvalComments });
            this.showToast('Success', 'Selected expenses rejected successfully.', 'success');
            this.selectedRows = [];
            this.approvalComments ='';
            return refreshApex(this.wiredDataResult);
        } catch (err) {
            this.showToast('Error', err.body?.message || err.message, 'error');
        }
    }
    //Expense Input chage
    hadleExpenseCommentsChange(event)
    {
        const value = event.target.value;
        this.approvalComments = value;
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}