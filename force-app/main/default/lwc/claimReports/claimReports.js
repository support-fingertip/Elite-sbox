import { LightningElement, track } from 'lwc';
import getCategorySlabClaimCategorySummary from '@salesforce/apex/DMSPortalLwc.getCategorySlabClaimCategorySummary';
import getCategorySlabClaimCategoryCustomerDetail from '@salesforce/apex/DMSPortalLwc.getCategorySlabClaimCategoryCustomerDetail';
import getSchemeClaimCustomerSummary from '@salesforce/apex/DMSPortalLwc.getSchemeClaimCustomerSummary';

export default class ClaimReports extends LightningElement {
    @track selectedReport = null;
    @track fromDate = '';
    @track toDate = '';
    @track isLoading = false;
    @track groupedData = [];
    @track hasData = false;

    reportOptions = [
        {
            id: 'categorySummary',
            label: 'Category Slab Claim — Category-Wise Summary',
            description: 'View category slab claim amounts grouped by customer category'
        },
        {
            id: 'categoryCustomerDetail',
            label: 'Category Slab Claim — Category + Customer Detail',
            description: 'View category slab claim amounts grouped by category and customer'
        },
        {
            id: 'schemeCustomerSummary',
            label: 'Scheme Claim — Customer-Wise Summary',
            description: 'View scheme claim amounts grouped by customer'
        }
    ];

    get isReportSelection() {
        return this.selectedReport === null;
    }

    get isCategorySummary() {
        return this.selectedReport === 'categorySummary';
    }

    get isCategoryCustomerDetail() {
        return this.selectedReport === 'categoryCustomerDetail';
    }

    get isSchemeCustomerSummary() {
        return this.selectedReport === 'schemeCustomerSummary';
    }

    get reportTitle() {
        const opt = this.reportOptions.find(r => r.id === this.selectedReport);
        return opt ? opt.label : '';
    }

    get showReport() {
        return this.selectedReport !== null;
    }

    get showNoData() {
        return !this.isLoading && !this.hasData && this.selectedReport !== null;
    }

    initializeDates() {
        const today = new Date();
        const firstDate = new Date(today.getFullYear(), today.getMonth(), 1);
        const lastDate = new Date(today.getFullYear(), today.getMonth() + 1, 0);
        const formatDate = (date) => date.toLocaleDateString('en-CA');
        this.fromDate = formatDate(firstDate);
        this.toDate = formatDate(lastDate);
    }

    handleReportSelect(event) {
        const reportId = event.currentTarget.dataset.id;
        this.selectedReport = reportId;
        this.initializeDates();
        this.fetchReportData();
    }

    handleBack() {
        this.selectedReport = null;
        this.groupedData = [];
        this.hasData = false;
    }

    handleDateChange(event) {
        const field = event.target.dataset.field;
        if (field === 'fromDate') {
            this.fromDate = event.target.value;
        } else if (field === 'toDate') {
            this.toDate = event.target.value;
        }
        this.fetchReportData();
    }

    fetchReportData() {
        if (!this.fromDate || !this.toDate) return;

        this.isLoading = true;
        let apexMethod;

        if (this.selectedReport === 'categorySummary') {
            apexMethod = getCategorySlabClaimCategorySummary;
        } else if (this.selectedReport === 'categoryCustomerDetail') {
            apexMethod = getCategorySlabClaimCategoryCustomerDetail;
        } else if (this.selectedReport === 'schemeCustomerSummary') {
            apexMethod = getSchemeClaimCustomerSummary;
        }

        apexMethod({ fromDate: this.fromDate, toDate: this.toDate })
            .then(result => {
                this.processData(result);
                this.isLoading = false;
            })
            .catch(error => {
                console.error('Error fetching claim report data:', error);
                this.groupedData = [];
                this.hasData = false;
                this.isLoading = false;
            });
    }

    processData(data) {
        if (!data || data.length === 0) {
            this.groupedData = [];
            this.hasData = false;
            return;
        }

        if (this.selectedReport === 'categorySummary') {
            this.groupedData = this.groupByCategory(data);
        } else if (this.selectedReport === 'categoryCustomerDetail') {
            this.groupedData = this.groupByCategoryAndCustomer(data);
        } else if (this.selectedReport === 'schemeCustomerSummary') {
            this.groupedData = this.groupByCustomer(data);
        }

        this.hasData = this.groupedData.length > 0;
    }

    groupByCategory(data) {
        const rows = [];
        let currentCategory = null;
        let subtotalQty = 0;
        let subtotalClaim = 0;
        let subtotalAmount = 0;
        let grandTotalQty = 0;
        let grandTotalClaim = 0;
        let grandTotalAmount = 0;
        let sno = 0;

        data.forEach((item, index) => {
            const cat = item.category || 'Uncategorized';

            if (currentCategory !== null && currentCategory !== cat) {
                rows.push({
                    key: 'sub-' + currentCategory,
                    rowType: 'subtotal',
                    label: currentCategory + ' Subtotal',
                    quantity: subtotalQty,
                    claimAmount: subtotalClaim,
                    totalAmount: subtotalAmount
                });
                subtotalQty = 0;
                subtotalClaim = 0;
                subtotalAmount = 0;
            }

            if (currentCategory !== cat) {
                rows.push({
                    key: 'grp-' + cat,
                    rowType: 'groupHeader',
                    label: cat
                });
                currentCategory = cat;
            }

            sno++;
            const qty = item.quantity || 0;
            const claim = item.claimAmount || 0;
            const total = item.totalAmount || 0;

            rows.push({
                key: 'row-' + index,
                rowType: 'data',
                sno: sno,
                productName: item.productName,
                beforePrice: this.fmt(item.beforePrice),
                afterPrice: this.fmt(item.afterPrice),
                quantity: qty,
                claimAmount: this.fmt(claim),
                totalAmount: this.fmt(total),
                rawQty: qty,
                rawClaim: claim,
                rawTotal: total
            });

            subtotalQty += qty;
            subtotalClaim += claim;
            subtotalAmount += total;
            grandTotalQty += qty;
            grandTotalClaim += claim;
            grandTotalAmount += total;
        });

        if (currentCategory !== null) {
            rows.push({
                key: 'sub-' + currentCategory + '-last',
                rowType: 'subtotal',
                label: currentCategory + ' Subtotal',
                quantity: subtotalQty,
                claimAmount: subtotalClaim,
                totalAmount: subtotalAmount
            });
        }

        rows.push({
            key: 'grand-total',
            rowType: 'grandtotal',
            label: 'Grand Total',
            quantity: grandTotalQty,
            claimAmount: grandTotalClaim,
            totalAmount: grandTotalAmount
        });

        return this.formatTotalRows(rows);
    }

    groupByCategoryAndCustomer(data) {
        const rows = [];
        let currentCategory = null;
        let currentCustomer = null;
        let subtotalQty = 0;
        let subtotalClaim = 0;
        let subtotalAmount = 0;
        let grandTotalQty = 0;
        let grandTotalClaim = 0;
        let grandTotalAmount = 0;
        let sno = 0;

        data.forEach((item, index) => {
            const cat = item.category || 'Uncategorized';
            const cust = item.customerName || 'Unknown';
            const groupKey = cat + '||' + cust;
            const prevGroupKey = currentCategory && currentCustomer ? currentCategory + '||' + currentCustomer : null;

            if (prevGroupKey !== null && prevGroupKey !== groupKey) {
                rows.push({
                    key: 'sub-' + prevGroupKey,
                    rowType: 'subtotal',
                    label: currentCategory + ' / ' + currentCustomer + ' Subtotal',
                    quantity: subtotalQty,
                    claimAmount: subtotalClaim,
                    totalAmount: subtotalAmount
                });
                subtotalQty = 0;
                subtotalClaim = 0;
                subtotalAmount = 0;
            }

            if (currentCategory !== cat) {
                rows.push({
                    key: 'catgrp-' + cat,
                    rowType: 'groupHeader',
                    label: cat
                });
            }

            if (currentCategory !== cat || currentCustomer !== cust) {
                rows.push({
                    key: 'custgrp-' + groupKey,
                    rowType: 'subGroupHeader',
                    label: cust
                });
                currentCategory = cat;
                currentCustomer = cust;
            }

            sno++;
            const qty = item.quantity || 0;
            const claim = item.claimAmount || 0;
            const total = item.totalAmount || 0;

            rows.push({
                key: 'row-' + index,
                rowType: 'data',
                sno: sno,
                productName: item.productName,
                customerName: cust,
                beforePrice: this.fmt(item.beforePrice),
                afterPrice: this.fmt(item.afterPrice),
                quantity: qty,
                claimAmount: this.fmt(claim),
                totalAmount: this.fmt(total),
                rawQty: qty,
                rawClaim: claim,
                rawTotal: total
            });

            subtotalQty += qty;
            subtotalClaim += claim;
            subtotalAmount += total;
            grandTotalQty += qty;
            grandTotalClaim += claim;
            grandTotalAmount += total;
        });

        if (currentCategory !== null && currentCustomer !== null) {
            rows.push({
                key: 'sub-last',
                rowType: 'subtotal',
                label: currentCategory + ' / ' + currentCustomer + ' Subtotal',
                quantity: subtotalQty,
                claimAmount: subtotalClaim,
                totalAmount: subtotalAmount
            });
        }

        rows.push({
            key: 'grand-total',
            rowType: 'grandtotal',
            label: 'Grand Total',
            quantity: grandTotalQty,
            claimAmount: grandTotalClaim,
            totalAmount: grandTotalAmount
        });

        return this.formatTotalRows(rows);
    }

    groupByCustomer(data) {
        const rows = [];
        let currentCustomer = null;
        let subtotalQty = 0;
        let subtotalClaim = 0;
        let subtotalAmount = 0;
        let grandTotalQty = 0;
        let grandTotalClaim = 0;
        let grandTotalAmount = 0;
        let sno = 0;

        data.forEach((item, index) => {
            const cust = item.customerName || 'Unknown';

            if (currentCustomer !== null && currentCustomer !== cust) {
                rows.push({
                    key: 'sub-' + currentCustomer,
                    rowType: 'subtotal',
                    label: currentCustomer + ' Subtotal',
                    quantity: subtotalQty,
                    claimAmount: subtotalClaim,
                    totalAmount: subtotalAmount
                });
                subtotalQty = 0;
                subtotalClaim = 0;
                subtotalAmount = 0;
            }

            if (currentCustomer !== cust) {
                rows.push({
                    key: 'grp-' + cust,
                    rowType: 'groupHeader',
                    label: cust
                });
                currentCustomer = cust;
            }

            sno++;
            const qty = item.quantity || 0;
            const claim = item.claimAmount || 0;
            const total = item.totalAmount || 0;

            rows.push({
                key: 'row-' + index,
                rowType: 'data',
                sno: sno,
                productName: item.productName,
                beforePrice: this.fmt(item.beforePrice),
                afterPrice: this.fmt(item.afterPrice),
                quantity: qty,
                claimAmount: this.fmt(claim),
                totalAmount: this.fmt(total),
                rawQty: qty,
                rawClaim: claim,
                rawTotal: total
            });

            subtotalQty += qty;
            subtotalClaim += claim;
            subtotalAmount += total;
            grandTotalQty += qty;
            grandTotalClaim += claim;
            grandTotalAmount += total;
        });

        if (currentCustomer !== null) {
            rows.push({
                key: 'sub-' + currentCustomer + '-last',
                rowType: 'subtotal',
                label: currentCustomer + ' Subtotal',
                quantity: subtotalQty,
                claimAmount: subtotalClaim,
                totalAmount: subtotalAmount
            });
        }

        rows.push({
            key: 'grand-total',
            rowType: 'grandtotal',
            label: 'Grand Total',
            quantity: grandTotalQty,
            claimAmount: grandTotalClaim,
            totalAmount: grandTotalAmount
        });

        return this.formatTotalRows(rows);
    }

    formatTotalRows(rows) {
        return rows.map(row => {
            if (row.rowType === 'subtotal' || row.rowType === 'grandtotal') {
                return {
                    ...row,
                    quantity: row.quantity,
                    claimAmount: this.fmt(row.claimAmount),
                    totalAmount: this.fmt(row.totalAmount),
                    isSubtotal: row.rowType === 'subtotal',
                    isGrandTotal: row.rowType === 'grandtotal',
                    isGroupHeader: false,
                    isSubGroupHeader: false,
                    isData: false
                };
            }
            return {
                ...row,
                isSubtotal: false,
                isGrandTotal: false,
                isGroupHeader: row.rowType === 'groupHeader',
                isSubGroupHeader: row.rowType === 'subGroupHeader',
                isData: row.rowType === 'data'
            };
        });
    }

    fmt(value) {
        if (value === null || value === undefined) return '0.00';
        return Number(value).toLocaleString('en-IN', {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        });
    }
}