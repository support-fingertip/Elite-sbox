import { LightningElement, api } from 'lwc';
import getProductMappings from '@salesforce/apex/SecondaryCustomerController.getProductMappings';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class SecondaryCustomers extends LightningElement {
    @api recordId;
    productMappings = [];
    searchKey = '';
    isLoading = false;
    fileName = '';
    totalCustomersCount = 0;
    subStockiestCount = 0;
    secondaryCustomerCount = 0;
    label='Secondary Customers'

    get filteredData() {
        if (!this.searchKey) return this.productMappings;
        const key = this.searchKey.toLowerCase();
        return this.productMappings.filter(item =>
            (item.secondaryCustomerName && item.secondaryCustomerName.toLowerCase().includes(key)) ||
            (item.secondaryCustomerOutletId && item.secondaryCustomerOutletId.toLowerCase().includes(key)) ||
            (item.secondaryCustomerCode && item.secondaryCustomerCode.toLowerCase().includes(key))
        );
    }

    get showNoRecords() {
        return this.filteredData.length === 0;
    }

    connectedCallback() {
        this.fetchProductMappings();
    }

    fetchProductMappings() {
        this.isLoading = true;
        getProductMappings({ recordId: this.recordId })
            .then((data) => {
                this.productMappings = data.customerData || [];
                this.fileName = data.fileName || '';
                this.totalCustomersCount =  data.totalCustomersCount || 0;
                this.subStockiestCount = data.subStockiestCount || 0;
                this.secondaryCustomerCount = data.secondaryCustomerCount || 0;
                this.label = 'Secondary Customers'+' ( '+ this.totalCustomersCount +' )';
       
                this.isLoading = false;
            })
            .catch((error) => {
                this.isLoading = false;
                console.error('Error fetching secondary customers:', error);
            });
    }

    handleSearch(event) {
        this.searchKey = event.target.value;
    }

    downloadCSV() {
        if (!this.productMappings || this.productMappings.length === 0) {
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
            const bom = '\uFEFF'; // Excel-compatible BOM
            let csv = bom + 'Salesforce.com Id,Secondary Customer,Outlet ID,Customer Code,Primary Phone Number,State,Disrict,Executive Name,Executive Code,Beat Id\n';

            this.productMappings.forEach(item => {
                const row = [
                    item.recordId || '',
                    item.secondaryCustomerName || '',
                    item.secondaryCustomerOutletId || '',
                    item.secondaryCustomerCode || '',
                    item.primaryPhoneNumber || '',
                    item.state || '',
                    item.disrict || '',
                    item.executiveName || '',
                    item.executiveCode || '',
                    item.beatId || '',
                ].map(value =>
                    `"${String(value).replace(/"/g, '""').replace(/\n/g, ' ')}"`
                ).join(',');
                csv += row + '\n';
            });

            const blob = new Blob([csv], { type: 'application/octet-stream' });
            const link = document.createElement('a');
            link.href = URL.createObjectURL(blob);
            link.download = this.fileName+'_Secondary_Customers.csv';
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

    navigateToCustomer(event) {
        const empId = event.currentTarget.dataset.id;
        if (empId) {
            const url = `/lightning/r/Account/${empId}/view`;
            window.open(url, '_blank');
        }
    }
}