import { LightningElement, track } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import XLSX_LIB from '@salesforce/resourceUrl/xlsxLibrary';
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
    xlsxLoaded = false;

    connectedCallback() {
        console.log('SecondaryCustomerLedger connectedCallback called');
        this.initializeDates();
        loadScript(this, XLSX_LIB)
            .then(() => {
                this.xlsxLoaded = true;
                console.log('XLSX library loaded successfully');
            })
            .catch(error => {
                console.error('Failed to load XLSX library:', error);
            });
    }
    

    toggleDownloadMenu() {
        this.showDownloadMenu = !this.showDownloadMenu;
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

        // Step 1: Fetch opening balance
        getOpeningBalance({
            customerId: this.selectedCustomerId,
            asOfDate: this.fromDate
        })
        .then(openingBalResult => {
            const openingBalance = Number(openingBalResult?.balance) || 0;
            console.log('Opening Balance:', openingBalance);

            // Step 2: Fetch ledger transactions
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

            // Step 3: Opening Balance Row
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

            // Step 4: Process ledger entries
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

                // Correct running balance
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

            // Step 5: Combine data
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


    // Safe formatter (prevents NaN)
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
// ─────────────────────────────────────────────
// Export XLSX — uses SheetJS loaded via loadScript
// ─────────────────────────────────────────────
handleExportXlsx() {
    this.showDownloadMenu = false;
    if (!this.allLedgerData || this.allLedgerData.length === 0) {
        this.showToast('Export Error', 'No ledger data to export', 'error');
        return;
    }
    if (!this.xlsxLoaded || !window.XLSX) {
        this.showToast('Export Error', 'XLSX library not loaded yet. Please wait a moment and try again.', 'error');
        return;
    }

    try {
        const xlsxLib = window.XLSX;
        const headers = [
            'S.No.', 'Transaction Date', 'Doc Type',
            'Doc No', 'Debit (INR)', 'Credit (INR)', 'Balance (INR)'
        ];

        const rows = this.allLedgerData.map(record => [
            record.rowIndex       || '',
            record.transactionDate|| '',
            record.description    || '',
            record.referenceNo    || '',
            record.debitAmount    || '',
            record.creditAmount   || '',
            record.balance        || ''
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

        // Generate XLSX as array buffer and download via Blob
        const wbout = xlsxLib.write(wb, { bookType: 'xlsx', type: 'array' });
        const blob = new Blob([wbout], { type: 'application/octet-stream' });
        const url  = URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href     = url;
        link.download = `Ledger_${this.customerName || 'Customer'}_${this.fromDate}_to_${this.toDate}.xlsx`;
        link.style.display = 'none';
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        URL.revokeObjectURL(url);

    } catch (error) {
        console.error('XLSX Export Error:', error);
        this.showToast('Export Error', 'Failed to export Excel file: ' + error.message, 'error');
    }
}


// ─────────────────────────────────────────────
// Export PDF — opens printable HTML via Blob URL (LWS-safe, no popup block)
// ─────────────────────────────────────────────
handleExportPdf() {
    this.showDownloadMenu = false;
    if (!this.allLedgerData || this.allLedgerData.length === 0) {
        this.showToast('Export Error', 'No ledger data to export', 'error');
        return;
    }

    try {
        const title = 'Ledger - ' + (this.customerName || 'Customer') + ' (' + this.fromDate + ' to ' + this.toDate + ')';

        // Build table rows
        let tableRows = '';
        this.allLedgerData.forEach(record => {
            const rowBg = record.isOpeningBalance
                ? 'background:#dceff5;font-weight:bold;'
                : '';
            tableRows +=
                '<tr style="' + rowBg + '">' +
                    '<td>' + (record.rowIndex || '') + '</td>' +
                    '<td>' + (record.transactionDate || '') + '</td>' +
                    '<td>' + (record.description || '') + '</td>' +
                    '<td>' + (record.referenceNo || '') + '</td>' +
                    '<td style="text-align:right;">' + (record.debitAmount || '') + '</td>' +
                    '<td style="text-align:right;">' + (record.creditAmount || '') + '</td>' +
                    '<td style="text-align:right;font-weight:bold;">' + (record.balance || '') + '</td>' +
                '</tr>';
        });

        const htmlContent =
            '<!DOCTYPE html><html><head><meta charset="UTF-8"/>' +
            '<title>' + title + '</title>' +
            '<style>' +
                'body{font-family:Arial,sans-serif;font-size:12px;margin:20px;color:#333;}' +
                'h2{color:#02323e;font-size:15px;margin-bottom:14px;}' +
                'table{width:100%;border-collapse:collapse;}' +
                'th{background:#02323e;color:#fff;padding:8px 10px;text-align:left;font-size:11px;}' +
                'td{padding:7px 10px;border-bottom:1px solid #e0e0e0;font-size:11px;}' +
                '@media print{body{margin:8px;}h2{font-size:13px;}@page{size:landscape;margin:10mm;}}' +
            '</style></head><body>' +
            '<h2>' + title + '</h2>' +
            '<table><thead><tr>' +
                '<th>S.No.</th><th>Transaction Date</th><th>Doc Type</th><th>Doc No</th>' +
                '<th style="text-align:right;">Debit (\u20B9)</th>' +
                '<th style="text-align:right;">Credit (\u20B9)</th>' +
                '<th style="text-align:right;">Balance (\u20B9)</th>' +
            '</tr></thead><tbody>' + tableRows + '</tbody></table>' +
            '</body></html>';

        // Create Blob URL — same-origin, not blocked like data: URIs
        const blob = new Blob([htmlContent], { type: 'text/html' });
        const blobUrl = URL.createObjectURL(blob);
        const printWindow = window.open(blobUrl, '_blank');

        if (printWindow) {
            printWindow.onload = function() {
                printWindow.focus();
                printWindow.print();
            };
            // Clean up blob URL after delay
            setTimeout(() => URL.revokeObjectURL(blobUrl), 60000);
        } else {
            // Fallback: download as HTML file if popup blocked
            URL.revokeObjectURL(blobUrl);
            const downloadBlob = new Blob([htmlContent], { type: 'text/plain' });
            const downloadUrl = URL.createObjectURL(downloadBlob);
            const link = document.createElement('a');
            link.href = downloadUrl;
            link.download = 'Ledger_' + (this.customerName || 'Customer') + '_' + this.fromDate + '_to_' + this.toDate + '.html';
            link.style.display = 'none';
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
            URL.revokeObjectURL(downloadUrl);
            this.showToast('Info', 'PDF print was blocked. HTML file downloaded instead — open it and press Ctrl+P to print as PDF.', 'info');
        }

    } catch (error) {
        console.error('PDF Export Error:', error);
        this.showToast('Export Error', 'Failed to export PDF: ' + error.message, 'error');
    }
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