import { LightningElement, api, track } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import SHEETJS from '@salesforce/resourceUrl/SheetJS';
import getSecondaryCustomerAgingReport from '@salesforce/apex/DMSPortalLwc.getSecondaryCustomerAgingReport';

export default class SecondaryCustomerAgingReport extends LightningElement {
    @api customerId;
    @api customerName;

    @track agingBuckets = [];
    @track totalInvoicePending = 0;
    @track totalDebitNotePending = 0;
    @track totalAgingAmount = 0;
    @track isLoading = true;
    @track showDownloadMenu = false;

    sheetJsLoaded = false;

    connectedCallback() {
        this.fetchAgingReport();
        if (!this.sheetJsLoaded) {
            loadScript(this, SHEETJS)
                .then(() => { this.sheetJsLoaded = true; })
                .catch(err => { console.error('SheetJS load error:', err); });
        }
    }

    fetchAgingReport() {
        this.isLoading = true;
        getSecondaryCustomerAgingReport({ customerId: this.customerId })
            .then(result => {
                if (result) {
                    this.agingBuckets = result.buckets.map(b => ({
                        label: b.label,
                        invoiceAmount: b.invoiceAmount || 0,
                        debitNoteAmount: b.debitNoteAmount || 0,
                        totalAmount: b.totalAmount || 0,
                        formattedTotal: this.formatCurrency(b.totalAmount || 0)
                    }));
                    this.totalInvoicePending = result.totalInvoicePending || 0;
                    this.totalDebitNotePending = result.totalDebitNotePending || 0;
                    this.totalAgingAmount = result.totalAgingAmount || 0;
                }
                this.isLoading = false;
            })
            .catch(error => {
                console.error('Error fetching aging report:', error);
                this.isLoading = false;
            });
    }

    formatCurrency(value) {
        return Number(value).toLocaleString('en-IN', {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        });
    }

    get formattedInvoicePending() {
        return '₹' + this.formatCurrency(this.totalInvoicePending);
    }

    get formattedDebitNotePending() {
        return '₹' + this.formatCurrency(this.totalDebitNotePending);
    }

    get formattedTotalAging() {
        return '₹' + this.formatCurrency(this.totalAgingAmount);
    }

    handleBack() {
        this.dispatchEvent(new CustomEvent('back'));
    }

    // ---------- Download ----------

    toggleDownloadMenu() {
        this.showDownloadMenu = !this.showDownloadMenu;
    }

    get exportHeaders() {
        return ['Age Bucket', 'Invoice Pending (₹)', 'Debit Note Pending (₹)', 'Total Amount (₹)'];
    }

    get exportRows() {
        const rows = this.agingBuckets.map(b => [
            b.label,
            b.invoiceAmount,
            b.debitNoteAmount,
            b.totalAmount
        ]);
        rows.push(['Total', this.totalInvoicePending, this.totalDebitNotePending, this.totalAgingAmount]);
        return rows;
    }

    get exportFileName() {
        return `Aging_Report_${this.customerName || 'Customer'}`;
    }

    // CSV Export
    handleExportCsv() {
        this.showDownloadMenu = false;
        if (!this.agingBuckets || this.agingBuckets.length === 0) {
            return;
        }

        try {
            const headers = this.exportHeaders;
            const rows = this.exportRows;

            const csvContent = [headers, ...rows]
                .map(row => row.map(cell => `"${String(cell).replace(/"/g, '""')}"`).join(','))
                .join('\n');

            const blob = new Blob(['\ufeff' + csvContent], { type: 'text/plain' });
            const url = URL.createObjectURL(blob);
            const link = document.createElement('a');
            link.href = url;
            link.download = this.exportFileName + '.csv';
            link.style.display = 'none';
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
            URL.revokeObjectURL(url);
        } catch (error) {
            console.error('CSV Export Error:', error);
        }
    }

    // XLSX Export
    handleExportXlsx() {
        this.showDownloadMenu = false;
        if (!this.agingBuckets || this.agingBuckets.length === 0) {
            return;
        }

        try {
            const XLSX = window.XLSX;
            if (!XLSX) {
                console.error('Excel library not loaded yet, please retry');
                return;
            }

            const headers = this.exportHeaders;
            const rows = this.exportRows;
            const wsData = [headers, ...rows];
            const ws = XLSX.utils.aoa_to_sheet(wsData);

            ws['!cols'] = [
                { wch: 18 },
                { wch: 20 },
                { wch: 24 },
                { wch: 20 }
            ];

            const wb = XLSX.utils.book_new();
            XLSX.utils.book_append_sheet(wb, ws, 'Aging Report');
            XLSX.writeFile(wb, this.exportFileName + '.xlsx');
        } catch (error) {
            console.error('XLSX Export Error:', error);
        }
    }

    // PDF Export (window.print overlay — same pattern as secondaryCustomerLedger)
    handleExportPdf() {
        this.showDownloadMenu = false;
        if (!this.agingBuckets || this.agingBuckets.length === 0) {
            return;
        }

        try {
            const title = `Aging Report — ${this.customerName || 'Customer'}`;

            let rowsHtml = '';
            this.agingBuckets.forEach(b => {
                rowsHtml += `<tr>
                    <td>${b.label}</td>
                    <td class="num">${this.formatCurrency(b.invoiceAmount)}</td>
                    <td class="num">${this.formatCurrency(b.debitNoteAmount)}</td>
                    <td class="num bold">${this.formatCurrency(b.totalAmount)}</td>
                </tr>`;
            });

            // Total row
            rowsHtml += `<tr style="background:#dceef5;font-weight:bold;">
                <td>Total</td>
                <td class="num">${this.formatCurrency(this.totalInvoicePending)}</td>
                <td class="num">${this.formatCurrency(this.totalDebitNotePending)}</td>
                <td class="num bold">${this.formatCurrency(this.totalAgingAmount)}</td>
            </tr>`;

            const printDiv = document.createElement('div');
            printDiv.id = 'lwc-print-overlay';
            printDiv.innerHTML = `
                <style id="lwc-print-style">
                    @media print {
                        body > *:not(#lwc-print-overlay) { display: none !important; }
                        #lwc-print-overlay { display: block !important; }
                    }
                </style>
                <div id="lwc-print-content">
                    <h2>${title}</h2>
                    <table>
                        <thead>
                            <tr>
                                <th>Age Bucket</th>
                                <th class="num">Invoice Pending (&#8377;)</th>
                                <th class="num">Debit Note Pending (&#8377;)</th>
                                <th class="num">Total Amount (&#8377;)</th>
                            </tr>
                        </thead>
                        <tbody>${rowsHtml}</tbody>
                    </table>
                </div>
                <style>
                    #lwc-print-overlay {
                        display: none;
                        position: fixed;
                        top: 0; left: 0;
                        width: 100%; height: 100%;
                        background: white;
                        z-index: 99999;
                        padding: 20px;
                        box-sizing: border-box;
                    }
                    #lwc-print-content {
                        font-family: Arial, sans-serif;
                        font-size: 12px;
                        color: #333;
                    }
                    #lwc-print-content h2 {
                        font-size: 14px;
                        color: #02323e;
                        margin-bottom: 12px;
                    }
                    #lwc-print-content table {
                        width: 100%;
                        border-collapse: collapse;
                    }
                    #lwc-print-content th {
                        background: #02323e;
                        color: #fff;
                        padding: 7px 9px;
                        font-size: 11px;
                        text-align: left;
                    }
                    #lwc-print-content td {
                        padding: 6px 9px;
                        border-bottom: 1px solid #e0e0e0;
                        font-size: 11px;
                    }
                    #lwc-print-content .num  { text-align: right; }
                    #lwc-print-content .bold { font-weight: bold; }
                </style>`;

            document.body.appendChild(printDiv);

            // eslint-disable-next-line @lwc/lwc/no-async-operation
            setTimeout(() => {
                window.print();
                const cleanup = () => {
                    const overlay = document.getElementById('lwc-print-overlay');
                    if (overlay) overlay.parentNode.removeChild(overlay);
                    window.removeEventListener('afterprint', cleanup);
                };
                window.addEventListener('afterprint', cleanup);
                // Fallback cleanup
                // eslint-disable-next-line @lwc/lwc/no-async-operation
                setTimeout(cleanup, 5000);
            }, 100);
        } catch (error) {
            console.error('PDF Export Error:', error);
        }
    }
}