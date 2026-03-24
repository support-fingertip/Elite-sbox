import { LightningElement, api, track } from 'lwc';
import getSecondaryCustomerAgingReport from '@salesforce/apex/DMSPortalLwc.getSecondaryCustomerAgingReport';

export default class SecondaryCustomerAgingReport extends LightningElement {
    @api customerId;
    @api customerName;

    @track agingBuckets = [];
    @track totalInvoicePending = 0;
    @track totalDebitNotePending = 0;
    @track totalAgingAmount = 0;
    @track isLoading = true;

    connectedCallback() {
        this.fetchAgingReport();
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

    handleDownloadCSV() {
        const header = ['Age Bucket', 'Invoice Pending', 'Debit Note Pending', 'Total Amount'];
        const rows = this.agingBuckets.map(b => [
            b.label,
            b.invoiceAmount,
            b.debitNoteAmount,
            b.totalAmount
        ]);
        rows.push(['Total', this.totalInvoicePending, this.totalDebitNotePending, this.totalAgingAmount]);

        let csvContent = '\uFEFF' + header.join(',') + '\n';
        rows.forEach(row => {
            csvContent += row.join(',') + '\n';
        });

        const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
        const link = document.createElement('a');
        link.href = URL.createObjectURL(blob);
        link.download = `Aging_Report_${this.customerName || 'Customer'}.csv`;
        link.click();
        URL.revokeObjectURL(link.href);
    }
}
