import { LightningElement, track } from 'lwc';
import searchCustomers from '@salesforce/apex/DMSPortalLwc.searchCustomers';
import saveSecondaryReceipt from '@salesforce/apex/DMSPortalLwc.saveSecondaryReceipt';
import allSecondaryReceiptData from '@salesforce/apex/DMSPortalLwc.allSecondaryReceiptData';
import getPendingSecondaryInvoicesByCustomer from '@salesforce/apex/DMSPortalLwc.getPendingSecondaryInvoicesByCustomer';
import getSecondaryReceiptItemsByReceiptId from '@salesforce/apex/DMSPortalLwc.getSecondaryReceiptItemsByReceiptId';

export default class NewSecondaryReceipt extends LightningElement {
    @track showReceiptItemsPage = false;
    @track selectedReceiptId = null;
    @track selectedReceiptNo = null;
    @track pendingInvoices = [];
    @track payingNowMap = {};
    @track amountMessage = '';
    @track showNewSecondaryReceiptForm = false;
    @track customerSearch = '';
    @track selectedReceipt = null;
    @track receiptItems = [];
    @track hasReceiptItems = false;
    isPageLoaded = false;
    isReceiptPageLoaded = false;
    showinvoices = false;

    get isAutoFillDisabled() {
        const enteredAmount = parseFloat(this.totalAmount) || 0;
        const totalPending = this.pendingInvoices.reduce((sum, inv) => sum + (inv.pendingAmount || 0), 0);
        return enteredAmount > totalPending && totalPending > 0;
    }

    closeReceiptDetail() {
        this.selectedReceipt = null;
    }


    handleReceiptClick(event) {
        const receiptId = event.currentTarget.dataset.id;
        const found = this.receipts.find(r => r.id === receiptId);
        if (found) {
            this.selectedReceiptId = found.id;
            this.selectedReceiptNo = found.receiptNo;
            this.showReceiptItemsPage = true;
            this.fetchReceiptItems(found.id);
        }
    }

    fetchReceiptItems(receiptId) {
        this.isSubPartLoad = true;
        getSecondaryReceiptItemsByReceiptId({ receiptId: receiptId })
            .then(result => {
               this.receiptItems = result.map((item, index) => ({
                    rowIndex: index + 1,
                    Name: item.Name,
                    CreatedDate: item.CreatedDate 
                        ? new Date(item.CreatedDate).toLocaleDateString('en-GB').replace(/\//g, '-') 
                        : '',
                    Amount: item.Amount__c
                }));
                 this.isSubPartLoad = false;
                this.hasReceiptItems = this.receiptItems.length > 0;
            })
            .catch(error => {
                this.receiptItems = [];
                this.hasReceiptItems = false;
            });
    }

    handleBackToReceipts() {
        this.showReceiptItemsPage = false;
        this.selectedReceiptId = null;
        this.selectedReceiptNo = null;
        this.receiptItems = [];
        this.hasReceiptItems = false;
    }

    downloadReceiptsAsCSV() {
        if (!this.originalReceipts || this.originalReceipts.length === 0) {
            if (this.showToast) {
                this.showToast('No Data Found', 'No secondary receipts found for the selected filters.', 'error');
            } else {
                alert('No secondary receipts found for the selected filters.');
            }
            return;
        }
        const header = ['S.No.', 'Receipt No', 'Customer Name', 'Payment Date', 'Payment Mode', 'Reference No', 'Remark'];
        const rows = this.originalReceipts.map(rec => [
            rec.rowIndex,
            rec.receiptNo || '',
            rec.customerName || '',
            rec.paymentDate || '',
            rec.paymentMode || '',
            rec.referenceNumber || '',
            rec.remarks || ''
        ]);
        let csvContent = 'data:text/csv;charset=utf-8,' + header.join(',') + '\n';
        rows.forEach(row => {
            csvContent += row.join(',') + '\n';
        });
        const encodedUri = encodeURI(csvContent);
        const link = document.createElement('a');
        link.setAttribute('href', encodedUri);
        link.setAttribute('download', 'secondary_receipts.csv');
        link.click();
    }

    handleListCustomerSearch(event) {
        this.searchSecondaryCustomerName = event.detail.value || event.target.value;
        this.applyListFilters();
    }

    selectListCustomer(event) {
        const selectedName = event.currentTarget.dataset.name;
        this.searchSecondaryCustomerName = selectedName;
        this.showListCustomerSuggestions = false;
        this.applyListFilters();
    }

    applyListFilters() {
        let filtered = [...this.originalReceipts];
        if (this.searchReceiptNo) {
            const key = this.searchReceiptNo.toLowerCase();
            filtered = filtered.filter(n => n.receiptNo && n.receiptNo.toLowerCase().includes(key));
        }
        if (this.searchSecondaryCustomerName) {
            const key = this.searchSecondaryCustomerName.toLowerCase();
            filtered = filtered.filter(n => n.customerName && n.customerName.toLowerCase().includes(key));
        }
        this.receipts = filtered.length > 0 ? filtered : null;
    }

    handleNewSecondaryReceipt() {
        this.showNewSecondaryReceiptForm = true;
    }

    handleCancel() {
        this.showNewSecondaryReceiptForm = false;
        this.customerSearch = '';
        this.selectedCustomerId = '';
        this.filteredCustomers = [];
        this.showCustomerSuggestions = false;
        this.paymentDate = new Date().toLocaleDateString('en-CA');
        this.paymentMode = '';
        this.referenceNumber = '';
        this.totalAmount = null;
        this.remarks = '';
        this.loadReceipts();
    }
    @track customerOptions = [];
    @track selectedCustomerId = '';
    @track filteredCustomers = [];
    @track showCustomerSuggestions = false;
    @track customerName = '';

    // New fields for Secondary Receipt
    @track paymentDate = '';
    @track paymentMode = '';
    @track paymentModeOptions = [
        { label: 'Cash', value: 'Cash' },
        { label: 'Cheque', value: 'Cheque' },
        { label: 'NEFT', value: 'NEFT' },
        { label: 'RTGS', value: 'RTGS' },
        { label: 'IMPS', value: 'IMPS' },
        { label: 'UPI', value: 'UPI' },
        { label: 'Other', value: 'Other' }
    ];
    @track referenceNumber = '';
    @track totalAmount = null;
    @track remarks = '';

    // List view properties
    @track receipts = [];
    @track originalReceipts = [];
    @track fromDate = '';
    @track toDate = '';
    @track searchReceiptNo = '';
    @track searchSecondaryCustomerName = '';
    @track filteredListCustomers = [];
    @track showListCustomerSuggestions = false;

    isPageLoaded = false;
    isSubPartLoad = false;

    connectedCallback() {
        const today = new Date();
        this.paymentDate = today.toLocaleDateString('en-CA');
        this.initReceiptList();
    }

    initReceiptList() {
        const today = new Date();
        const firstDate = new Date(today.getFullYear(), today.getMonth(), 1);
        const lastDate = new Date(today.getFullYear(), today.getMonth() + 1, 0);
        const formatDate = (d) => d.toLocaleDateString('en-CA');
        this.fromDate = formatDate(firstDate);
        this.toDate = formatDate(lastDate);
        this.loadReceipts();
    }

    loadReceipts() {
        this.isSubPartLoad = true;
        allSecondaryReceiptData({ frmDate: this.fromDate, toDate: this.toDate, status: '' })
            .then(result => {
                const data = result.totalSecondaryReceiptData || [];
                if (result.reasonOptions) {
                    this.reasonOptions = result.reasonOptions
                        .filter(opt => opt.value !== 'All')
                        .map(opt => ({ label: opt.label, value: opt.value }));
                }
                this.originalReceipts = data.map((rec, index) => ({
                    id: rec.receiptId,
                    rowIndex: index + 1,
                    receiptNo: rec.receiptNo, // This should be the auto number field (Secondary Receipt Name)
                    customerName: rec.customerName,
                    paymentDate: rec.paymentDate,
                    paymentMode: rec.paymentMode,
                    referenceNumber: rec.referenceNumber,
                    remarks: rec.remarks,
                    totalAmount:rec.totalAmount
                }));
                this.receipts = [...this.originalReceipts];
                this.isSubPartLoad = false;
            })
            .catch(error => {
                console.error('Error loading receipts:', error);
                this.isSubPartLoad = false;
            });
    }

    handleFromDateChange(event) {
        this.fromDate = event.target.value;
        this.searchReceiptNo = '';
        this.searchSecondaryCustomerName = '';
        this.loadReceipts();
    }

    handleToDateChange(event) {
        this.toDate = event.target.value;
        this.searchReceiptNo = '';
        this.searchSecondaryCustomerName = '';
        this.loadReceipts();
    }

    handleSearchReceiptNo(event) {
        this.searchReceiptNo = event.target.value;
        this.applyListFilters();
    }

    handleListCustomerFocus() {
        this.showListCustomerSuggestions = false;
    }
    // Handlers for new fields
    handlePaymentDateChange(event) {
        this.paymentDate = event.target.value;
    }
    handlePaymentModeChange(event) {
        this.paymentMode = event.detail.value;
    }
    handleReferenceNumberChange(event) {
        this.referenceNumber = event.target.value;
    }
    handleTotalAmountChange(event) {
        this.totalAmount = event.target.value;
        // Validation: entered amount should not exceed total pending amount
        const enteredAmount = parseFloat(this.totalAmount) || 0;
        const totalPending = this.pendingInvoices.reduce((sum, inv) => sum + (inv.pendingAmount || 0), 0);
        if (enteredAmount > totalPending && totalPending > 0) {
            this.amountMessage = 'Entered amount exceeds pending amount. Please check and enter a valid amount.';
        } else {
            this.handleAutoFillOldestFirst();
            this.amountMessage = '';
        }
    
    }
    handleRemarksChange(event) {
        this.remarks = event.target.value;
    }


    handleCustomerFocus() {
        this.showCustomerSuggestions = false;
    }

    handleCustomerSearch(event) {
        this.customerSearch = event.target.value;
        const searchVal = this.customerSearch?.trim();

        // Reset if empty or cleared
        if (!searchVal || searchVal.length < 2) {
            this.filteredCustomers = [];
            this.showCustomerSuggestions = false;
            this.selectedCustomerId = '';
            this.showinvoices = false;
            return;
        }

        // Call Apex search
        searchCustomers({ searchKey: searchVal })
            .then(result => {
                this.filteredCustomers = result.map(acc => ({
                    label: acc.Name,
                    value: acc.Id
                }));
                this.customerOptions = this.filteredCustomers;
                this.showCustomerSuggestions = this.filteredCustomers.length > 0;
            })
            .catch(error => {
                console.error('Customer search error', error);
                this.filteredCustomers = [];
                this.showCustomerSuggestions = false;
            });
    }

    selectCustomer(event) {
        this.selectedCustomerId = event.currentTarget.dataset.id;
        const selected = this.filteredCustomers.find(c => c.value === this.selectedCustomerId);
        this.customerSearch = selected ? selected.label : '';
        this.customerName = selected ? selected.label : '';
        this.showCustomerSuggestions = false;
        this.showinvoices = true;
        // Fetch pending invoices for this customer
        if (this.selectedCustomerId) {
            this.isPageLoaded = true;
            getPendingSecondaryInvoicesByCustomer({ customerId: this.selectedCustomerId })
                .then(result => {
                 
                    // Log the raw Apex result for debugging property names
                    console.log('Apex raw result:', result);
                    this.pendingInvoices = result.map(inv => ({
                        InvId: inv.InvId,
                        name: inv.name,
                        InvDate: inv.InvDate,
                        invoiceAmount: inv.Amount != null ? inv.Amount : 0, // Grand Total (Invoice Amount)
                        alreadyPaid: inv.paidAmount != null ? inv.paidAmount : 0, // Paid Invoice Amount
                        pendingAmount: inv.pendingAmount != null ? inv.pendingAmount : 0, // Pending Amount
                        payingNow: 0,
                        balance: inv.pendingAmount != null ? Math.round((inv.pendingAmount + Number.EPSILON) * 100) / 100 : 0
                    }));
                    this.payingNowMap = {};
                    this.isPageLoaded = false;
                })
                .catch(error => {
                    console.error('Apex error for pending invoices:', error);
                    this.pendingInvoices = [];
                    this.payingNowMap = {};
                });
        } else {
            this.pendingInvoices = [];
            this.payingNowMap = {};
        }
    }

    handlePayingNowChange(event) {
        const index = event.target.dataset.index;
        const value = parseFloat(event.target.value) || 0;
        this.payingNowMap[index] = value;
        // Optionally update balance in UI
        this.pendingInvoices = this.pendingInvoices.map((inv, i) => {
            if (i == index) {
                const payingNow = value;
                let balance = (inv.pending || 0) - payingNow;
                balance = Math.round((balance + Number.EPSILON) * 100) / 100;
                return { ...inv, payingNow, balance };
            }
            return inv;
        });
    }

    handleAutoFillOldestFirst() {
        let amountLeft = parseFloat(this.totalAmount) || 0;
        // Sort invoices by date ascending (oldest first)
        let sorted = [...this.pendingInvoices].sort((a, b) => {
            const parseDate = (d) => {
                if (!d) return new Date(0);
                if (d.includes('/')) {
                    const [day, month, year] = d.split('/').map(Number);
                    return new Date(year, month - 1, day);
                } else if (d.includes('-')) {
                    const [year, month, day] = d.split('-').map(Number);
                    return new Date(year, month - 1, day);
                }
                return new Date(d);
            };
            return parseDate(a.InvDate) - parseDate(b.InvDate);
        });

        // Allocate amount to oldest invoices first
        let allocation = [];
        for (let inv of sorted) {
            let pay = 0;
            if (amountLeft > 0) {
                pay = Math.min(inv.pendingAmount, amountLeft);
                amountLeft -= pay;
            }
            let balance = inv.pendingAmount - pay;
            balance = Math.round((balance + Number.EPSILON) * 100) / 100;
            allocation.push({ ...inv, payingNow: pay, balance });
        }

        // Map allocation back to original UI order
        this.pendingInvoices = this.pendingInvoices.map(inv => {
            const found = allocation.find(a => a.InvId === inv.InvId);
            return found ? found : inv;
        });
        // Optionally, update payingNowMap for consistency
        this.payingNowMap = {};
        this.pendingInvoices.forEach((inv, idx) => {
            this.payingNowMap[idx] = inv.payingNow;
        });
    }

    // You should update handleSave to use the new fields and call saveSecondaryReceipt
    handleCancel() {
        this.showNewSecondaryReceiptForm = false;
        this.customerSearch = '';
        this.selectedCustomerId = '';
        this.showinvoices = false;
        this.filteredCustomers = [];
        this.showCustomerSuggestions = false;
        this.customerName = '';
        this.paymentDate = new Date().toLocaleDateString('en-CA');
        this.paymentMode = '';
        this.referenceNumber = '';
        this.totalAmount = null;
        this.remarks = '';
        this.loadReceipts();
    }

    handleSave() {
        // Validate required fields
        if (!this.selectedCustomerId || !this.paymentDate || !this.paymentMode || !this.totalAmount) {
            // Show error toast (implement as needed)
            this.showToast('Validation Error', 'Please select all required fields.', 'error');
            return;
        }
        const totalPending = this.pendingInvoices.reduce((sum, inv) => sum + (inv.pendingAmount || 0), 0);
        if(this.totalAmount > totalPending)
        {
            this.showToast('Validation Error', 'Total Amount is greater than pending', 'error');
            return;
        }



       
        const receiptData = {
            sobjectType: 'Secondary_Receipt__c',
            Customer__c: this.selectedCustomerId,
            Payment_Date__c: this.paymentDate,
            Payment_Mode__c: this.paymentMode,
            Reference_Number__c: this.referenceNumber,
            Total_Amount__c: this.totalAmount,
            Remarks__c: this.remarks
        };
        const recipetItems = [];
        for (let item of this.pendingInvoices) {
            // Add this line to inspect the data
            recipetItems.push({
                sobjectType: 'Secondary_Receipt_Item__c',
                Secondary_Invoice__c: item.InvId,
                Amount__c:  item.payingNow
            });
        }
        this.isPageLoaded = true;
        saveSecondaryReceipt({ 
            receiptData: receiptData,
            recipetItems : recipetItems
              })
            .then(() => {
                this.isPageLoaded = false;
                this.showNewSecondaryReceiptForm = false;
                this.showToast('Success', 'Receipt created successfully', 'Success');
                this.initReceiptList();
                // Show success toast (implement as needed)
            })
            .catch(error => {
                // Show error toast (implement as needed)
                console.error('Error saving receipt:', error);
            });
    }

    // Custom Toast method (to use c-custom-toast)
    showToast(title, message, variant) {
        const toast = this.template.querySelector('c-custom-toast');
        console.log('Custom Toast component:', toast);
        if (toast) {
            toast.showToast(variant, message);
        } else {
            console.error('Custom Toast component not found!');
        }
    }
}