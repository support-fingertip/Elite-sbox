import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getOrderItems from '@salesforce/apex/TransactionController.getOrderItems';

const PAGE_SIZE = 100;
const SEARCH_DEBOUNCE_MS = 300;

export default class OrderItems extends NavigationMixin(LightningElement) {
    @api recordId;
    @track allOrderItems = [];
    @track filteredItems = [];
    @track groupedOrderItems = [];
    searchKey = '';
    isLoading = false;
    showOrderItems = false;

    _visibleCount = PAGE_SIZE;
    _searchDebounceId;

    get orderItemsCount() {
        return this.filteredItems ? this.filteredItems.length : 0;
    }

    get hasMore() {
        return this._visibleCount < this.filteredItems.length;
    }

    get loadMoreLabel() {
        const remaining = this.filteredItems.length - this._visibleCount;
        const next = Math.min(PAGE_SIZE, remaining);
        return `Load More (${next} of ${remaining} remaining)`;
    }

    get isDownloadDisabled() {
        return !this.allOrderItems || this.allOrderItems.length === 0;
    }

    connectedCallback() {
        this.loadOrderItems();
    }

    loadOrderItems() {
        this.isLoading = true;
        getOrderItems({ accountId: this.recordId })
        .then((data) => {
            this.allOrderItems = data || [];
            this.filteredItems = this.allOrderItems;
            this._visibleCount = PAGE_SIZE;
            this._rebuildGroups();
            this.error = undefined;
            this.isLoading = false;
        })
        .catch((error) => {
            this.error = error;
            this.allOrderItems = [];
            this.filteredItems = [];
            this.groupedOrderItems = [];
            this.showOrderItems = false;
            this.isLoading = false;
        });
    }

    // Re-group only the currently visible slice; keeps DOM small for large lists.
    _rebuildGroups() {
        const slice = this.filteredItems.slice(0, this._visibleCount);
        this.groupedOrderItems = this._groupByDate(slice);
        this.showOrderItems = this.groupedOrderItems.length > 0;
    }

    _groupByDate(items) {
        if (!items || items.length === 0) {
            return [];
        }

        const groups = {};
        items.forEach(item => {
            const dateKey = item.OrderDate
                ? item.OrderDate
                : item.CreatedDate
                ? item.CreatedDate.split('T')[0]
                : 'No Date';

            if (!groups[dateKey]) {
                groups[dateKey] = [];
            }
            groups[dateKey].push(item);
        });

        return Object.keys(groups)
            .sort((a, b) => new Date(b) - new Date(a))
            .map(dateVal => ({ date: dateVal, items: groups[dateVal] }));
    }

    // Debounced search across the full in-memory list.
    handleSearch(event) {
        const value = event.target.value || '';
        if (this._searchDebounceId) {
            clearTimeout(this._searchDebounceId);
        }
        this._searchDebounceId = setTimeout(() => {
            this.searchKey = value.toLowerCase();
            if (this.searchKey) {
                this.filteredItems = this.allOrderItems.filter(
                    item => item.ProductName &&
                        item.ProductName.toLowerCase().includes(this.searchKey)
                );
            } else {
                this.filteredItems = this.allOrderItems;
            }
            this._visibleCount = PAGE_SIZE;
            this._rebuildGroups();
        }, SEARCH_DEBOUNCE_MS);
    }

    handleLoadMore() {
        this._visibleCount += PAGE_SIZE;
        this._rebuildGroups();
    }

    downloadCSV() {
        if (!this.allOrderItems || this.allOrderItems.length === 0) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Warning',
                    message: 'No data available to download.',
                    variant: 'warning'
                })
            );
            return;
        }

        try {
            const bom = '\uFEFF';
            let csv = bom + 'Order Date,Order Name,SKU,Each Qty,Case Qty,Unit Price,Tax %,Non Taxable Amt,Tax Amt,Total Amt,Net Weight,Delivered Qty,Delivered Qty (Cases),Delivered Net Weight\n';

            this.allOrderItems.forEach(item => {
                const row = [
                    item.OrderDate || '',
                    item.OrderName || '',
                    item.ProductName || '',
                    item.eachQuantity,
                    item.CaseQuantity,
                    item.UnitPrice,
                    item.taxPercent,
                    item.AmountWithOutTax,
                    item.taxAmount,
                    item.totalAmount,
                    item.NetWeight,
                    item.DeliveredQty,
                    item.DeliveredQtyInCases,
                    item.DeliveredNetWeight
                ].map(value => {
                    const s = value === null || value === undefined ? '' : String(value);
                    return `"${s.replace(/"/g, '""').replace(/\n/g, ' ')}"`;
                }).join(',');
                csv += row + '\n';
            });

            const blob = new Blob([csv], { type: 'application/octet-stream' });
            const link = document.createElement('a');
            link.href = URL.createObjectURL(blob);
            link.download = 'Transactions.csv';
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
            URL.revokeObjectURL(link.href);
        } catch (error) {
            console.error('Error generating CSV:', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Failed to download CSV. Please try again.',
                    variant: 'error'
                })
            );
        }
    }
}
