import { LightningElement, track } from 'lwc';

import getSubordinateUsers from '@salesforce/apex/ceoDashboardController.getFilteredData';
import getOutletCounts from '@salesforce/apex/ceoDashboardController.getOutletCounts';
import getPJPOutlets from '@salesforce/apex/ceoDashboardController.getPJPOutlets';
import getPJPProductiveOutlets from '@salesforce/apex/ceoDashboardController.getPJPProductiveOutlets';
import getNonPJPOutlets from '@salesforce/apex/ceoDashboardController.getNonPJPOutlets';
import getOrderMetrics from '@salesforce/apex/ceoDashboardController.getOrderMetrics';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getPJPCalls from '@salesforce/apex/ceoDashboardController.getPJPCalls';
import getNonPJPCalls from '@salesforce/apex/ceoDashboardController.getNonPJPCalls';

export default class DashboardLwc extends LightningElement {
    fromDate;
    toDate;
    salesChannel = '';
    rsm = '';
    asm = '';
    isLoading = false;

    salesChannelOptions = [];
    rsmOptions = [];
    asmOptions = [];

    // STATIC VALUES
    activeOutletCount = 0;
    activationPendingOutletCount = 0;
        
    pjpOutlets = 0;
    pjpProductiveOutlets = 0;
    pjpProductiveOutletsPercent = 0;
        
    nonPJPOutlets = 0;
    nonPJPProductiveOutlets = 0;
    nonPJPProductiveOutletsPercent = 0;
        
    pjpCalls = 0;
    pjpProductiveCalls = 0;
    pjpProductiveCallsPercent = 0;
        
    nonPJPCalls = 0;
    nonPJPProductiveCalls = 0;
    nonPJPProductiveCallsPercent = 0;
        
    totalCalls = 0;
    totalProductiveCalls = 0;
    totalProductiveCallsPercent = 0;

    valueinLakhs = 0;
    orderWeightinKG = 0;

    selectedRange = 'ThisWeek';
    isCustomSelected = false;

    refreshRSMList = true;
    refreshASMList = true;
    refreshSalesChanelList = true;

    // ROW 1: Active Outets
    row1 = [
        { id: 1, title: "New Active Outlets", value: 0 },
        { id: 2, title: "New Activation Pending Outlets", value: 0 }
    ];

    // ROW 2: PJP Unique Outlets
    row2 = [
        { id: 3, title: "PJP Visited Outlets", value: 0 ,isPercent : false},
        { id: 4, title: "PJP Visited Productive Outlets", value: 0,isPercent : false },
        { id: 5, title: "PJP Productive Outlets %", value: 0,isPercent : true }
    ];

    // ROW 3: Non PJP Unique Outlets
    row3 = [
        { id: 6, title: "Non PJP Visited Outlets", value: 0,isPercent : false },
        { id: 7, title: "Non PJP Visited Productive Outlets", value: 0,isPercent : false },
        { id: 8, title: "Non PJP Productive Outlets %", value: 0,isPercent : true }
    ];

    // ROW 4: Total Calls
    row4 = [
        { id: 9, title: "Total Calls (PJP & Non PJP)", value: 0 ,isPercent : false},
        { id: 10, title: "Total Productive Calls (PJP & Non PJP)", value: 0,isPercent : false },
        { id: 11, title: "Total Productive Calls (PJP & Non PJP) %", value: 0 ,isPercent : true}
    ];

     // ROW 5: PJP Calls
    row5 = [
        { id: 12, title: "Total Calls (PJP)", value: 0 ,isPercent : false},
        { id: 13, title: "Total Productive Calls (PJP)", value: 0 ,isPercent : false},
        { id: 14, title: "Total Productive Calls (PJP) %", value: 0 ,isPercent : true}
    ];

    
    // ROW 6: NON PJP Calls
    row6 = [
        { id: 15, title: "Total Calls (Non PJP)", value: 0 ,isPercent : false},
        { id: 16, title: "Total Productive Calls (Non PJP)", value: 0 ,isPercent : false},
        { id: 17, title: "Total Productive Calls (Non PJP) %", value: 0 ,isPercent : true}
    ];

    // ROW 7: Order Qty and Amount
    row7 = [
        { id: 18, title: "Qty (Ton's)", value: 0 ,isPercent : false},
        { id: 19, title: "Value (Lakhs)", value: 0 ,isPercent : false}
    ];

    get rangeOptions() {
        return [
            { label: 'All', value: 'All' },
            { label: 'Custom', value: 'Custom' },
            { label: 'Today', value: 'Today' },
            { label: 'This Week', value: 'ThisWeek' },
            { label: 'Last Week', value: 'LastWeek' },
            { label: 'This Month', value: 'ThisMonth' },
            { label: 'Last Month', value: 'LastMonth' },
            { label: 'This Year', value: 'ThisYear' },
            { label: 'Last Year', value: 'LastYear' }
        ];
    }
    subordinateUserIds = [];


    connectedCallback() {
        this.isLoading = true;

        const today = new Date();
        const formatDate = (date) => date.toLocaleDateString('en-CA'); // YYYY-MM-DD format

        // For today, both fromDate and toDate are the same
        this.fromDate = formatDate(today);
        this.toDate = formatDate(today);

        this.getData();
    }


    getData() {
        if (!navigator.onLine) {
            this.showToast('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }

        this.isLoading = true;

        // Step 1: Get Subordinate Users
        getSubordinateUsers({ saleChannel: this.salesChannel, rsmId: this.rsm , asmId : this.asm})
            .then(result => {
                if (this.refreshRSMList) 
                { 
                    this.rsmOptions = this.getPicklistValues(result.rsmUserList || []);
                } 
                if (this.refreshASMList) 
                { 
                    this.asmOptions = this.getPicklistValues(result.asmUserList || []);
                } 
                if (this.refreshSalesChanelList) 
                { 
                    this.salesChannelOptions = this.getPicklistValuesDirect(result.salesChannelOptions || []);
                }


                this.subordinateUserIds = result.userIds;

                // Step 2: Get Outlet Counts
                return getOutletCounts({
                    subordinateUserIds: this.subordinateUserIds,
                    fromDate: this.fromDate,
                    toDate: this.toDate
                });
            })
            .then(outletCounts => {
                this.activeOutletCount = outletCounts.activeOutletCount;
                this.activationPendingOutletCount = outletCounts.activationPendingOutletCount;

                // Step 3: Get PJP Outlets
                return getPJPOutlets({
                    subordinateUserIds: this.subordinateUserIds,
                    fromDate: this.fromDate,
                    toDate: this.toDate
                });
            })
            .then(pjpData => {
                this.pjpOutlets = pjpData.pjpOutlets;
      

                // Step 4: Get Non-PJP Outlets
                return getPJPProductiveOutlets({
                    subordinateUserIds: this.subordinateUserIds,
                    fromDate: this.fromDate,
                    toDate: this.toDate
                });
            })
              .then(pjpData => {
                this.pjpProductiveOutlets = pjpData.pjpProductiveOutlets;

                this.pjpProductiveOutletsPercent = this.pjpOutlets > 0
                ? ((this.pjpProductiveOutlets / this.pjpOutlets) * 100).toFixed(2)
                : 0;


                // Step 4: Get Non-PJP Outlets
                return getNonPJPOutlets({
                    subordinateUserIds: this.subordinateUserIds,
                    fromDate: this.fromDate,
                    toDate: this.toDate
                });
            })
            .then(nonPJPData => {
                this.nonPJPOutlets = nonPJPData.nonPJPOutlets;
                this.nonPJPProductiveOutlets = nonPJPData.nonPJPProductiveOutlets;
                this.nonPJPProductiveOutletsPercent = nonPJPData.nonPJPProductiveOutletsPercent;

                // Step 5: Get Order Metrics
                return getPJPCalls({
                    subordinateUserIds: this.subordinateUserIds,
                    fromDate: this.fromDate,
                    toDate: this.toDate
                });
            })
            .then(pjpData => {
                this.pjpCalls = pjpData.pjpCalls;
                this.pjpProductiveCalls = pjpData.pjpProductiveCalls;
                this.pjpProductiveCallsPercent = pjpData.pjpProductiveCallsPercent;

                // Step 4: Get Non-PJP Calls
                return getNonPJPCalls({
                    subordinateUserIds: this.subordinateUserIds,
                    fromDate: this.fromDate,
                    toDate: this.toDate
                });
            })
            .then(nonPJPData => {
                this.nonPJPCalls = nonPJPData.nonPJPCalls;
                this.nonPJPProductiveCalls = nonPJPData.nonPJPProductiveCalls;
                this.nonPJPProductiveCallsPercent = nonPJPData.nonPJPProductiveCallsPercent;

                // Compute total calls
                this.totalCalls = this.pjpCalls + this.nonPJPCalls;
                this.totalProductiveCalls = this.pjpProductiveCalls + this.nonPJPProductiveCalls;
                this.totalProductiveCallsPercent = this.totalCalls > 0
                    ? ((this.totalProductiveCalls / this.totalCalls) * 100).toFixed(2)
                    : 0;

                this.updateCardValues();
    

                this.isLoading = false;




                // Step 5: Get Order Metrics
              /*  return getOrderMetrics({
                    subordinateUserIds: this.subordinateUserIds,
                    fromDate: this.fromDate,
                    toDate: this.toDate
                });*/


            })
          /*  .then(orderData => {
                this.orderWeightinKG = orderData.orderWeightinKG;
                this.valueinLakhs = orderData.valueinLakhs;

                // Compute total calls
                this.totalCalls = this.pjpCalls + this.nonPJPCalls;
                this.totalProductiveCalls = this.pjpProductiveCalls + this.nonPJPProductiveCalls;
                this.totalProductiveCallsPercent = this.totalCalls > 0
                    ? ((this.totalProductiveCalls / this.totalCalls) * 100).toFixed(2)
                    : 0;

                this.updateCardValues();
    

                this.isLoading = false;
            })*/
            
            .catch(error => {
            this.isLoading = false;

            // Log the raw error for debugging
            console.error('Raw error:', JSON.stringify(error));

            // Extract meaningful error message
            let message = 'Unknown error';
            
            if (Array.isArray(error.body)) {
                // Apex may return an array of errors
                message = error.body.map(e => e.message).join('; ');
            } else if (error.body && error.body.message) {
                message = error.body.message;
            } else if (error.message) {
                message = error.message;
            }
            console.error('message:', message);

            this.showToast('Error', 'Please update your date range or filters to continue', 'error');
        });

    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
    updateCardValues() {
        // Outlets Data
        this.row1[0].value = this.activeOutletCount;
        this.row1[1].value = this.activationPendingOutletCount;

        //PJP Unique Outlets
        this.row2[0].value = this.pjpOutlets;
        this.row2[1].value = this.pjpProductiveOutlets;
        this.row2[2].value = this.pjpProductiveOutletsPercent;

        //Non PJP Unique Outlets
        this.row3[0].value = this.nonPJPOutlets;
        this.row3[1].value = this.nonPJPProductiveOutlets;
        this.row3[2].value = this.nonPJPProductiveOutletsPercent;

        //Total calls
        this.row4[0].value = this.totalCalls;
        this.row4[1].value = this.totalProductiveCalls;
        this.row4[2].value = this.totalProductiveCallsPercent;

        //PJP calls
        this.row5[0].value = this.pjpCalls;
        this.row5[1].value = this.pjpProductiveCalls;
        this.row5[2].value = this.pjpProductiveCallsPercent;

        //NON PJP calls
        this.row6[0].value = this.nonPJPCalls;
        this.row6[1].value = this.nonPJPProductiveCalls;
        this.row6[2].value = this.nonPJPProductiveCallsPercent;

        this.row7[0].value = this.orderWeightinKG;
        this.row7[1].value = this.valueinLakhs;
        

    }

    format(d) {
        return d.toLocaleDateString('en-CA'); // yyyy-mm-dd
    }

    handleRangeChange(event) {
        this.selectedRange = event.target.value;
        this.isCustomSelected = false;

        const today = new Date();
        let from = null, to = null;

        switch (this.selectedRange) {

            case 'Today':
                from = new Date(today);
                to = new Date(today);
                break;

            case 'ThisWeek': {
                const current = new Date();
                const first = new Date(current.setDate(current.getDate() - current.getDay())); // Sunday
                const last = new Date(first);
                last.setDate(first.getDate() + 6); // Saturday

                from = first;
                to = last;
                break;
            }

            case 'LastWeek': {
                const current = new Date();
                // End of last week = last Sunday
                const lastWeekEnd = new Date(current.setDate(current.getDate() - current.getDay() - 1));
                // Start = last Monday
                const lastWeekStart = new Date(lastWeekEnd);
                lastWeekStart.setDate(lastWeekEnd.getDate() - 6);

                from = lastWeekStart;
                to = lastWeekEnd;
                break;
            }

            case 'ThisMonth':
                from = new Date(today.getFullYear(), today.getMonth(), 1);
                to   = new Date(today.getFullYear(), today.getMonth() + 1, 0);
                break;

            case 'LastMonth':
                from = new Date(today.getFullYear(), today.getMonth() - 1, 1);
                to   = new Date(today.getFullYear(), today.getMonth(), 0);
                break;

            case 'ThisYear':
                from = new Date(today.getFullYear(), 0, 1);
                to   = new Date(today.getFullYear(), 11, 31);
                break;

            case 'LastYear':
                from = new Date(today.getFullYear() - 1, 0, 1);
                to   = new Date(today.getFullYear() - 1, 11, 31);
                break;

            case 'Custom':
                this.isCustomSelected = true;
                from = new Date(today.getFullYear(), today.getMonth(), 1);
                to   = new Date(today.getFullYear(), today.getMonth() + 1, 0);
                break;

            case 'All':
                this.fromDate = null;
                this.toDate = null;
                this.refreshRSMList = false;
                this.refreshASMList = false;
                this.refreshSalesChanelList = false;
                this.getData();
                return; // stop processing
        }

        // Format only if not empty
        this.fromDate = this.format(from);
        this.toDate = this.format(to);

        // Avoid refreshing lists again
        this.refreshRSMList = false;
        this.refreshASMList = false;
        this.refreshSalesChanelList = false;

        this.getData();
    }



    handleSalesChannelChange(event)
    {
        this.salesChannel = event.target.value;
        this.refreshRSMList = true;
        this.refreshASMList = true;
        this.rsm = '';
        this.asm = '';
        this.refreshSalesChanelList = false;
        this.getData();
    }

    handleRSMChange(event)
    {
        this.rsm = event.target.value;
        this.asm = '';
        this.refreshRSMList = false;
        this.refreshSalesChanelList = false;
        this.refreshASMList = true;
        this.getData();
    }

    handleAMSChange(event)
    {
        this.asm = event.target.value;
        this.refreshRSMList = false;
        this.refreshASMList = false;
        this.refreshSalesChanelList = false;
        this.getData();
    }


    getPicklistValues(optionsArray) { 
        let list = [{ label: 'All', value: '' }];

        let mapped = optionsArray.map(option => ({
            label: option.Name,
            value: option.Id
        }));

        return list.concat(mapped);
    }
    getPicklistValuesDirect(optionsArray) {
        let list = [{ label: 'All', value: '' }];
        return list.concat(optionsArray); // optionsArray already contains label & value
    }

    handleFromDateChange(event)
    {
        this.fromDate = event.target.value;
        this.refreshRSMList = false;
        this.refreshASMList = false;
        this.refreshSalesChanelList = false;
        this.getData();
    }

    handleToDateChange(event)
    {
        this.toDate = event.target.value;
        this.refreshRSMList = false;
        this.refreshASMList = false;
        this.refreshSalesChanelList = false;
        this.getData();
    }



    handleChange(event) {
        console.log("Filter updated:", event.target.label, event.target.value);
    }

    handleRefresh() {
        this.fromDate = null;
        this.toDate = null;
        this.salesChannel = '';
        this.rsm = '';
        this.asm = '';
        this.refreshRSMList = true;
        this.refreshASMList = true;
        this.refreshSalesChanelList = true;

        this.getData();
    }

}