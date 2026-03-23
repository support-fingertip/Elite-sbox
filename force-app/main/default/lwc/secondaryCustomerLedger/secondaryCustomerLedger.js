import { LightningElement, track } from 'lwc';
import searchCustomers from '@salesforce/apex/DMSPortalLwc.searchCustomers';
import getSecondaryLedger from '@salesforce/apex/DMSPortalLwc.getSecondaryLedger';
import getOpeningBalance from '@salesforce/apex/DMSPortalLwc.getOpeningBalance';

export default class SecondaryCustomerLedger extends LightningElement {
    @track customerOptions = [];
    @track selectedCustomer = '';
    @track fromDate = '';
    @track toDate = '';
    @track srchVal = '';
    @track status = 'All';
    @track statusOptions = [
        { label: 'All', value: 'All' },
        { label: 'Active', value: 'Active' },
        { label: 'Inactive', value: 'Inactive' }
    ];
    @track allLedgerData = [];
    @track isDataExisted = false;
    @track isLoading = false;
    @track errorMessage = '';
    @track filteredCustomers = [];
    showCustomerSuggestions = false;
    selectedCustomerId = '';
    customerSearch = '';
    customerName = '';

    connectedCallback() {
        console.log('SecondaryCustomerLedger connectedCallback called');
        this.initializeDates();
    }

    initializeDates() {
        const today = new Date();
        const firstDate = new Date(today.getFullYear(), today.getMonth(), 1);
        const lastDate = new Date(today.getFullYear(), today.getMonth() + 1, 0);
        const formatDate = (date) => date.toLocaleDateString('en-CA');
        this.fromDate = formatDate(firstDate);
        this.toDate = formatDate(lastDate);
        this.status = 'All';
    }

    handleCustomerSearch(event) {
        this.customerSearch = event.target.value;
        const searchVal = this.customerSearch?.trim();

        // Reset if empty or too short
        if (!searchVal || searchVal.length < 2) {
            this.filteredCustomers = [];
            this.showCustomerSuggestions = false;
            this.selectedCustomerId = '';
            return;
        }

        searchCustomers({ searchKey: searchVal })
            .then(result => {
                this.filteredCustomers = result.map(acc => ({
                    label: acc.Name,
                    value: acc.Id
                }));
                this.showCustomerSuggestions = this.filteredCustomers.length > 0;
            })
            .catch(error => {
                console.error('Customer search error', error);
                this.filteredCustomers = [];
                this.showCustomerSuggestions = false;
            });
    }

    handleCustomerFocus() {
        if (this.filteredCustomers.length > 0) {
            this.showCustomerSuggestions = true;
        }
    }

    selectCustomer(event) {
        this.selectedCustomerId = event.currentTarget.dataset.id;
        const selected = this.filteredCustomers.find(c => c.value === this.selectedCustomerId);
        this.customerSearch = selected ? selected.label : '';
        this.customerName = selected ? selected.label : '';
        this.showCustomerSuggestions = false;
    }

    handleCustomerChange(event) {
        this.selectedCustomer = event.detail.value;
    }

    handleFromDateChange(event) {
        this.fromDate = event.detail.value;
    }

    handleToDateChange(event) {
        this.toDate = event.detail.value;
    }

    handleStatusChange(event) {
        this.status = event.detail.value;
    }

    handleSearchChange(event) {
        this.srchVal = event.detail.value;
    }

    handleGenerateLedger() {
        if (!this.selectedCustomerId) {
            this.showToast('Validation Error', 'Please select a Customer', 'error');
            return;
        }
        if (!this.fromDate || !this.toDate) {
            this.showToast('Validation Error', 'Please select both From Date and To Date', 'error');
            return;
        }

        this.isLoading = true;
        this.errorMessage = '';
        this.allLedgerData = [];
        this.isDataExisted = false;

        // Step 1: Fetch opening balance (sum of all transactions BEFORE fromDate)
        getOpeningBalance({
            customerId: this.selectedCustomerId,
            asOfDate: this.fromDate
        })
            .then(openingBalResult => {
                const openingBalance = openingBalResult ? (openingBalResult.balance || 0) : 0;
                console.log('Opening Balance:', openingBalance);

                // Step 2: Fetch ledger transactions within the date range
                return getSecondaryLedger({
                    customerId: this.selectedCustomerId,
                    fromDate: this.fromDate,
                    toDate: this.toDate,
                    status: this.status
                }).then(ledgerResult => ({ openingBalance, ledgerResult }));
            })
            .then(({ openingBalance, ledgerResult }) => {
                const ledgerData = ledgerResult ? (ledgerResult.ledgerData || []) : [];
                console.log('Ledger entries fetched:', ledgerData.length);
                this.showCustomerSuggestions = false;
                // Step 3: Build the opening balance row (always shown as first row)
                const openingRow = {
                    uniqueKey: 'opening-balance',
                    rowIndex: '1',
                    transactionDate: this.fromDate,
                    description: 'Opening Balance',
                    transactionNo: 'Opening Balance',
                    referenceNo: '-',
                    debitAmount: openingBalance > 0 ? this.formatAmount(openingBalance) : '',
                    creditAmount: openingBalance < 0 ? this.formatAmount(Math.abs(openingBalance)) : '',
                    balance: this.formatAmount(openingBalance),
                    isOpeningBalance: true,
                    rowClass: 'opening-balance-row'
                };

                // Step 4: Process each ledger entry with running balance
                let runningBalance = openingBalance;

                const processedData = ledgerData.map((entry, index) => {
                    const isDebit = entry.transactionType === 'Secondary Invoice' ||
                                     entry.transactionType === 'Invoice' ||
                                    entry.transactionType === 'Debit Note';
                    const isCredit = entry.transactionType === 'Receipt' ||
                                     entry.transactionType === 'Return' ||
                                     entry.transactionType === 'Credit Note';

                    const debitAmt  = isDebit  ? (entry.amount || 0) : 0;
                    const creditAmt = isCredit ? (entry.amount || 0) : 0;

                    // Running balance: add debits, subtract credits
                    runningBalance = runningBalance + debitAmt - creditAmt;

                    return {
                        ...entry,
                        uniqueKey: entry.transactionNo + '-' + index,
                        rowIndex: index + 2,
                        debitAmount:  debitAmt  > 0 ? this.formatAmount(debitAmt)  : '',
                        creditAmount: creditAmt > 0 ? this.formatAmount(creditAmt) : '',
                        balance: this.formatAmount(runningBalance),
                        isOpeningBalance: false,
                        rowClass: ''
                    };
                });

                // Step 5: Combine opening balance row + transaction rows
                this.allLedgerData = [openingRow, ...processedData];
                this.isDataExisted = processedData.length > 0;

                if (!this.isDataExisted) {
                    this.errorMessage = 'No ledger data found for the selected criteria';
                }

                this.isLoading = false;
            })
            .catch(error => {
                console.error('Error fetching ledger data:', error);
                this.errorMessage = 'Failed to fetch ledger data: ' + (error.body?.message || error.message || 'Unknown error');
                this.isLoading = false;
            });
    }

    // Format number to 2 decimal places with comma separation
    formatAmount(value) {
        if (value === null || value === undefined || value === '') return '';
        return Number(value).toLocaleString('en-IN', {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        });
    }

    handleExportCsv() {
    console.log('Export CSV clicked'); // Add this to confirm click is firing
    console.log('Ledger data length:', this.allLedgerData.length);

    if (!this.allLedgerData || this.allLedgerData.length === 0) {
        this.showToast('Export Error', 'No ledger data to export', 'error');
        return;
    }

    try {
        const headers = ['S.No.', 'Transaction Date', 'Doc Type', 'Doc No', 'Debit (INR)', 'Credit (INR)', 'Balance (INR)'];

        const rows = this.allLedgerData.map(record => [
            record.rowIndex || '',
            record.transactionDate || '',
            record.description || '',
            record.referenceNo || '',
            record.debitAmount || '',
            record.creditAmount || '',
            record.balance || ''
        ]);

        const csvContent = [headers, ...rows]
            .map(row => row.map(cell => `"${String(cell).replace(/"/g, '""')}"`).join(','))
            .join('\n');

        const blob = new Blob(['\ufeff' + csvContent], { type: 'text/plain' });
        const url = URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = url;
        link.download = `Ledger_${this.customerName || 'Customer'}_${this.fromDate}_to_${this.toDate}.csv`;
        link.style.display = 'none';
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        URL.revokeObjectURL(url);
    } catch (error) {
        console.error('CSV Export Error:', error);
        this.showToast('Export Error', 'Failed to export CSV', 'error');
    }
}
    handlePrint() {
        if (this.allLedgerData.length === 0) {
            this.showToast('Print Error', 'No ledger data to print', 'error');
            return;
        }
        window.print();
    }

    // Getter: controls table visibility
    get hasLedgerData() {
        return this.allLedgerData && this.allLedgerData.length > 0;
    }

    // Custom Toast helper
    showToast(title, message, variant) {
        const toast = this.template.querySelector('c-custom-toast');
        if (toast) {
            toast.showToast(variant, message);
        } else {
            console.error('Custom Toast component not found!');
        }
    }
}