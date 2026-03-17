import { LightningElement, track } from 'lwc';
import getSecondaryCustomers from '@salesforce/apex/DMSPortalLwc.getSecondaryCustomers';
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

	connectedCallback() {
		console.log('SecondaryCustomerLedger connectedCallback called');
		this.initializeDates();
		this.loadCustomers();
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

	loadCustomers() {
		console.log('Loading customers...');
		this.isLoading = true;
		this.errorMessage = '';
		
		getSecondaryCustomers({ status: 'All' })
			.then(result => {
				console.log('Customers received:', result);
				const customers = result.customerData || result || [];
				
				if (customers && customers.length > 0) {
					this.customerOptions = customers.map(customer => ({
						label: customer.secondaryCustomerName,
						value: customer.Id
					}));
					console.log('Customer options set:', this.customerOptions.length);
				} else {
					this.errorMessage = 'No secondary customers available';
					this.customerOptions = [];
				}
				this.isLoading = false;
			})
			.catch(error => {
				console.error('Error loading customers:', error);
				this.errorMessage = 'Failed to load customers: ' + (error.body?.message || error.message);
				this.customerOptions = [];
				this.isLoading = false;
			});
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
		if (!this.selectedCustomer) {
			this.errorMessage = 'Please select a customer';
			return;
		}
		if (!this.fromDate || !this.toDate) {
			this.errorMessage = 'Please select both From Date and To Date';
			return;
		}

		this.isLoading = true;
		this.errorMessage = '';
		this.allLedgerData = [];
		this.isDataExisted = false;

		console.log('Generating ledger with:', {
			customerId: this.selectedCustomer,
			fromDate: this.fromDate,
			toDate: this.toDate,
			status: this.status
		});

		// Fetch opening balance first
		getOpeningBalance({
			customerId: this.selectedCustomer,
			asOfDate: this.fromDate
		})
			.then(openingBalResult => {
				console.log('Opening Balance:', openingBalResult);
				const openingBalance = openingBalResult.balance || 0;
				
				// Now fetch ledger transactions
				return getSecondaryLedger({
					customerId: this.selectedCustomer,
					fromDate: this.fromDate,
					toDate: this.toDate,
					status: this.status
				}).then(ledgerResult => ({ openingBalance, ledgerResult }));
			})
			.then(({ openingBalance, ledgerResult }) => {
				console.log('Ledger Data:', ledgerResult);
				
				const ledgerData = ledgerResult.ledgerData || [];
				
				// Calculate running balance
				let runningBalance = openingBalance;
				const processedData = ledgerData.map((entry, index) => {
					// Determine if debit or credit
					const isDebit = entry.transactionType === 'Invoice' || entry.transactionType === 'Debit Note';
					const isCredit = entry.transactionType === 'Receipt' || entry.transactionType === 'Return' || entry.transactionType === 'Credit Note';
					
					const debitAmount = isDebit ? (entry.amount || 0) : 0;
					const creditAmount = isCredit ? (entry.amount || 0) : 0;
					
					runningBalance = runningBalance + debitAmount - creditAmount;
					
					return {
						...entry,
						rowIndex: index + 1,
						debitAmount: debitAmount,
						creditAmount: creditAmount,
						balance: runningBalance
					};
				});
				
				this.allLedgerData = processedData;
				this.isDataExisted = processedData.length > 0;
				
				if (!this.isDataExisted) {
					this.errorMessage = 'No ledger data found for selected criteria';
				}
				
				this.isLoading = false;
			})
			.catch(error => {
				console.error('Error fetching ledger data:', error);
				this.errorMessage = 'Failed to fetch ledger data: ' + (error.body?.message || error.message);
				this.isLoading = false;
			});
	}

	handleExportCsv() {
		if (this.allLedgerData.length === 0) {
			this.errorMessage = 'No ledger data to export';
			return;
		}
		// TODO: Implement CSV export logic
	}

	handlePrint() {
		if (this.allLedgerData.length === 0) {
			this.errorMessage = 'No ledger data to print';
			return;
		}
		window.print();
	}

	// Getter function (like Product Gallery hasProducts)
	get hasLedgerData() {
		return this.allLedgerData && this.allLedgerData.length > 0;
	}
}