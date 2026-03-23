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
    showDownloadMenu = false;
    _outsideClickHandler;

    connectedCallback() {
        console.log('SecondaryCustomerLedger connectedCallback called');
        this.initializeDates();
        this._outsideClickHandler = this.handleOutsideClick.bind(this);
    }

    disconnectedCallback() {
        document.removeEventListener('click', this._outsideClickHandler);
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
                    value: acc.Id,
                    landmark: acc.Land_Mark__c,
                    street: acc.Street__c
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

    // ── Download Dropdown ──
    toggleDownloadMenu(event) {
        event.stopPropagation();
        this.showDownloadMenu = !this.showDownloadMenu;
        if (this.showDownloadMenu) {
            document.addEventListener('click', this._outsideClickHandler);
        } else {
            document.removeEventListener('click', this._outsideClickHandler);
        }
    }

    handleOutsideClick() {
        this.showDownloadMenu = false;
        document.removeEventListener('click', this._outsideClickHandler);
    }

    // ── Export CSV ──
    handleExportCsv() {
        this.showDownloadMenu = false;
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

    // ── Export XLSX ──
    handleExportXlsx() {
        this.showDownloadMenu = false;
        if (!this.allLedgerData || this.allLedgerData.length === 0) {
            this.showToast('Export Error', 'No ledger data to export', 'error');
            return;
        }
        const xlsxLib = window.XLSX;
        if (!xlsxLib) {
            this.showToast('Export Error', 'XLSX library not available. Please try again.', 'error');
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
            const wsData = [headers, ...rows];
            const ws = xlsxLib.utils.aoa_to_sheet(wsData);

            // Auto-size columns
            ws['!cols'] = headers.map((h, i) => {
                const maxLen = Math.max(h.length, ...rows.map(r => String(r[i] || '').length));
                return { wch: maxLen + 2 };
            });

            const wb = xlsxLib.utils.book_new();
            xlsxLib.utils.book_append_sheet(wb, ws, 'Ledger');
            xlsxLib.writeFile(wb, `Ledger_${this.customerName || 'Customer'}_${this.fromDate}_to_${this.toDate}.xlsx`);
        } catch (error) {
            console.error('XLSX Export Error:', error);
            this.showToast('Export Error', 'Failed to export XLSX', 'error');
        }
    }

    // ── Export PDF (browser print) ──
    handleExportPdf() {
        this.showDownloadMenu = false;
        if (!this.allLedgerData || this.allLedgerData.length === 0) {
            this.showToast('Export Error', 'No ledger data to export', 'error');
            return;
        }
        try {
            const title = `Ledger - ${this.customerName || 'Customer'} (${this.fromDate} to ${this.toDate})`;

            let tableHtml = '<table border="1" cellpadding="6" cellspacing="0" style="border-collapse:collapse;width:100%;font-family:Arial,sans-serif;font-size:12px;">';
            tableHtml += '<thead><tr style="background:#02323e;color:#fff;">';
            tableHtml += '<th>S.No.</th><th>Transaction Date</th><th>Doc Type</th><th>Doc No</th>';
            tableHtml += '<th style="text-align:right;">Debit (\u20B9)</th>';
            tableHtml += '<th style="text-align:right;">Credit (\u20B9)</th>';
            tableHtml += '<th style="text-align:right;">Balance (\u20B9)</th>';
            tableHtml += '</tr></thead><tbody>';

            this.allLedgerData.forEach(record => {
                const bgStyle = record.isOpeningBalance ? 'background:#f0f4ff;' : '';
                tableHtml += '<tr style="' + bgStyle + '">' +
                    '<td>' + (record.rowIndex || '') + '</td>' +
                    '<td>' + (record.transactionDate || '') + '</td>' +
                    '<td>' + (record.description || '') + '</td>' +
                    '<td>' + (record.referenceNo || '') + '</td>' +
                    '<td style="text-align:right;">' + (record.debitAmount || '') + '</td>' +
                    '<td style="text-align:right;">' + (record.creditAmount || '') + '</td>' +
                    '<td style="text-align:right;font-weight:bold;">' + (record.balance || '') + '</td>' +
                    '</tr>';
            });
            tableHtml += '</tbody></table>';

            const printWindow = window.open('', '_blank');
            printWindow.document.write('<!DOCTYPE html>' +
                '<html><head><title>' + title + '</title>' +
                '<style>body{font-family:Arial,sans-serif;padding:20px;}h2{color:#02323e;margin-bottom:16px;}@media print{body{padding:0;}}</style>' +
                '</head><body>' +
                '<h2>' + title + '</h2>' +
                tableHtml +
                '</body></html>');
            printWindow.document.close();
            printWindow.focus();
            printWindow.print();
        } catch (error) {
            console.error('PDF Export Error:', error);
            this.showToast('Export Error', 'Failed to generate PDF', 'error');
        }
    }

    // ── Generate Ledger ──
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

        getOpeningBalance({
            customerId: this.selectedCustomerId,
            asOfDate: this.fromDate
        })
        .then(openingBalResult => {
            const openingBalance = Number(openingBalResult?.balance) || 0;
            console.log('Opening Balance:', openingBalance);

            return getSecondaryLedger({
                customerId: this.selectedCustomerId,
                fromDate: this.fromDate,
                toDate: this.toDate,
                status: this.status
            }).then(ledgerResult => ({ openingBalance, ledgerResult }));
        })
        .then(({ openingBalance, ledgerResult }) => {
            const ledgerData = ledgerResult?.ledgerData || [];
            console.log('Ledger entries fetched:', ledgerData.length);
            this.showCustomerSuggestions = false;

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

            let runningBalance = Number(openingBalance) || 0;
            const processedData = ledgerData.map((entry, index) => {
                const isDebit = entry.transactionType === 'Secondary Invoice' ||
                                entry.transactionType === 'Invoice' ||
                                entry.transactionType === 'Debit Note';
                const isCredit = entry.transactionType === 'Receipt' ||
                                entry.transactionType === 'Return' ||
                                entry.transactionType === 'Credit Note';
                const amount = Number(entry.amount) || 0;
                const debitAmt  = isDebit  ? amount : 0;
                const creditAmt = isCredit ? amount : 0;

                runningBalance = Number(runningBalance) + debitAmt - creditAmt;

                return {
                    ...entry,
                    uniqueKey: (entry.transactionNo || 'txn') + '-' + index,
                    rowIndex: index + 2,
                    debitAmount:  debitAmt  > 0 ? this.formatAmount(debitAmt)  : '',
                    creditAmount: creditAmt > 0 ? this.formatAmount(creditAmt) : '',
                    balance: this.formatAmount(runningBalance),
                    isOpeningBalance: false,
                    rowClass: ''
                };
            });

            this.allLedgerData = [openingRow, ...processedData];
            this.isDataExisted = processedData.length > 0;

            if (!this.isDataExisted) {
                this.errorMessage = 'No ledger data found for the selected criteria';
            }
            this.isLoading = false;
        })
        .catch(error => {
            console.error('Error fetching ledger data:', error);
            this.errorMessage = 'Failed to fetch ledger data: ' +
                (error.body?.message || error.message || 'Unknown error');
            this.isLoading = false;
        });
    }

    formatAmount(value) {
        const num = Number(value);
        if (isNaN(num)) {
            return '0.00';
        }
        return num.toLocaleString('en-IN', {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        });
    }

    handlePrint() {
        if (this.allLedgerData.length === 0) {
            this.showToast('Print Error', 'No ledger data to print', 'error');
            return;
        }
        window.print();
    }

    get hasLedgerData() {
        return this.allLedgerData && this.allLedgerData.length > 0;
    }

    showToast(title, message, variant) {
        const toast = this.template.querySelector('c-custom-toast');
        if (toast) {
            toast.showToast(variant, message);
        } else {
            console.error('Custom Toast component not found!');
        }
    }
}
