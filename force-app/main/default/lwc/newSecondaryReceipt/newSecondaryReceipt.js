import { LightningElement, track } from 'lwc';
    import searchCustomers from '@salesforce/apex/DMSPortalLwc.searchCustomers';
    import saveSecondaryReceipt from '@salesforce/apex/DMSPortalLwc.saveSecondaryReceipt';
    import allSecondaryReceiptData from '@salesforce/apex/DMSPortalLwc.allSecondaryReceiptData';

    export default class NewSecondaryReceipt extends LightningElement {
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
    @track showNewSecondaryReceiptForm = false;
    @track customerSearch = '';
    @track customerOptions = [];
    @track selectedCustomerId = '';
    @track filteredCustomers = [];
    @track showCustomerSuggestions = false;

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
                    remarks: rec.remarks
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
        this.showCustomerSuggestions = false;
    }

    // You should update handleSave to use the new fields and call saveSecondaryReceipt
    handleSave() {
        // Validate required fields
        if (!this.selectedCustomerId || !this.paymentDate || !this.paymentMode || !this.totalAmount) {
            // Show error toast (implement as needed)
            alert('Please fill all required fields.');
            return;
        }
        const receiptData = {
            customerId: this.selectedCustomerId,
            paymentDate: this.paymentDate,
            paymentMode: this.paymentMode,
            referenceNumber: this.referenceNumber,
            totalAmount: this.totalAmount,
            remarks: this.remarks
        };
        saveSecondaryReceipt({ receiptJson: JSON.stringify(receiptData) })
            .then(() => {
                this.showNewSecondaryReceiptForm = false;
                this.initReceiptList();
                // Show success toast (implement as needed)
            })
            .catch(error => {
                // Show error toast (implement as needed)
                console.error('Error saving receipt:', error);
            });
    }
}