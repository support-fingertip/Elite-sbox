import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import Get_DATA from '@salesforce/apex/EmployeeCustomerAssignmentController.getSecondaryCustomerAssignment';
import saveProductMappings from '@salesforce/apex/EmployeeCustomerAssignmentController.saveProductMappings';

export default class UserProfile_BeatPlan extends LightningElement {

    @api isDesktop = false;
    @api isMobile = false;
    @api recordId;
    @api objectName;

    viewScreen = true;
    editScreen = false;
    showItems = false;
    isSubPartLoad = false;
  

    //View Form
    @track dataViewItems = [];
    @track AlldataViewItems = [];
    searchKey = '';
    @track seachedCustomer = '';

    //Edit Form
    @track assignedPrimaryCustomers = [];
    @track relatedSubStockiestOptions = [];

    //Sub Stockiest
    selectedSubStockiest = '';
    searchedSecoundaryCustomer = '';
    showCustomers = false;


    //Primary customer search
    searchedPrimaryCustomers = [];
    isShowPrimaryCustomers = false;
 
    selectedPrimaryCustomerId = '';
    isPrimaryCustoerReadOnly = false;

    selectedPrimaryCustomer = '';
    isSuperStockiest = false;
    primaryCustomerOptions = [];
    primaryCustomerwithCustomerTypeMap = {};
    primaryCustomerToSubStockiestMap = {};
    @track sCustomerList = [];
    @track OriginalsCustomerList = [];
    @track relatedScustomers = [];
    @track OriginalRelatedScustomers = [];
     
    sortDirection = 'asc';

    @track previewCustomerList = [];
    productMappingToDeleteList = [];
    isPreviewDataExisted = false;
    selectedUserId = '';
    isEmployeeActive = true;
    assignCustomers = false; 
    is_SSA_DSM;
    @track currentUser = {};

    //Preview
    showPreview = false;

    //New Change 
    employeeId ='';
    isUserDeactivated = false;
    
    connectedCallback() {
        this.isSubPartLoad = true;
       // this.getAllData();
    }
    @api refreshData() {
        // Logic to refresh expense data
        this.getAllData() ;
    }
      
    getItemsWithIndex() {
        this.dataViewItems = this.dataViewItems.map((item, idx) => {
            return {
                ...item,
                displayIndex: idx + 1
            };
        });
    }
    //Get All Data
    getAllData()
    {
        if (!navigator.onLine) {
            this.isSubPartLoad = false;
            this.showToast('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        this.primaryCustomerToSubStockiestMap = {};
       
        this.isSubPartLoad = true;
        Get_DATA({
            recordId: this.recordId,
            objectName : this.objectName
        })
        .then(result => {
            this.dataViewItems = [];
            this.AlldataViewItems = [];
            this.assignedPrimaryCustomers =  result.primaryCustomers;
            this.isEmployeeActive = result.isEmployeeActive;
            this.sCustomerList = result.sCustomerList;
            this.OriginalsCustomerList = result.sCustomerList;
            this.selectedUserId = result.selectedUserId; 
            this.is_SSA_DSM = result.is_SSA_DSM;
            this.currentUser = result.currentUser;
            this.isUserDeactivated = result.isUserDeactivated;
            this.employeeId = result.employeeId;

            if (this.currentUser.isAdmin__c) {
                this.assignCustomers = true;
            } 
            //If user opned his own Employee record
            else if(!this.currentUser.isAdmin__c && this.currentUser.Id == this.selectedUserId)
            {
                this.assignCustomers = false;
            }
            //FOR TSE/TSM/ASM/RSM for Their Subordinates DSM/SSA
            //current user is not admin
            //current user is not SSA/DSM but selected user DSM
         
            else if (!this.currentUser.isAdmin__c && !this.currentUser.Is_SSA_DSM__c && this.is_SSA_DSM) {
                this.assignCustomers = true;
            }else {
                this.assignCustomers = false;
            }


            //Creating map to for Customer type
            this.primaryCustomerWithCustomerTypeMap = {};
            this.assignedPrimaryCustomers.forEach(cust => {
                this.primaryCustomerWithCustomerTypeMap[cust.Id] = cust.Primary_Customer_Type__c || '';
            });
            //Getting primary customers as Picklist
            this.primaryCustomerOptions = this.getPicklistValuesWithCode(result.primaryCustomers,'Name','Id', 'SAP_Customer_Code__c');

            if (result.sCustomerList && result.sCustomerList.length > 0) {
                // Temporary map to track unique Sub Stockiest customerIds for each primary
                const seenCustomerIdsMap = {};

                result.sCustomerList.forEach(sc => {
                    // Fill dataViewItems where isSelected is true
                    if (sc.isSelected) {
                        this.AlldataViewItems.push({
                            compositekey:sc.compositekey,
                            Id: sc.productMappingId,
                            customerCode:sc.customerCode,
                            outletId:sc.outletId,
                            customerName: sc.customerName,
                            customerType: sc.customerType,
                            primaryCustomerName : sc.primaryCustomerName,
                            parentSubstockiestName : sc.parentSubstockiestName,
                            isUnderSubStockiest:sc.isUnderSubStockiest
                        });
                    }

                    // Only for Sub Stockiest
                    if (sc.customerType === 'Sub Stockiest') {
                        const primaryId = sc.primaryCustomerId;
                        const customerId = sc.customerId;

                        // Initialize maps if not present
                        if (!this.primaryCustomerToSubStockiestMap[primaryId]) {
                            this.primaryCustomerToSubStockiestMap[primaryId] = [];
                            seenCustomerIdsMap[primaryId] = new Set();
                        }

                        // Add only if not already added
                        if (!seenCustomerIdsMap[primaryId].has(customerId)) {
                            this.primaryCustomerToSubStockiestMap[primaryId].push({
                                Name: sc.customerName,
                                Id: customerId,
                                customerCode:sc.customerCode
                            });
                            seenCustomerIdsMap[primaryId].add(customerId);
                        }
                    }
                });
                this.dataViewItems = [...this.AlldataViewItems];
                this.showItems = this.dataViewItems.length > 0;
                this.getItemsWithIndex();
                console.log('this.dataViewItems', JSON.stringify(this.dataViewItems));
            }

       
           
            this.isSubPartLoad = false;
        })
        .catch(error => {
            console.error(error);
            this.isSubPartLoad = false;
        });
    }
    handleSearch(event) {
        this.searchKey = event.target.value.toLowerCase();

        if (this.searchKey) {
            let searchedData = [];
            let objData = this.AlldataViewItems;

            for (let i = 0; i < objData.length; i++) {
                const obj = objData[i];
                const outletMatch = obj.outletId && obj.outletId.toLowerCase().includes(this.searchKey);
                const codeMatch = obj.customerCode && obj.customerCode.toLowerCase().includes(this.searchKey);
                const nameMatch = obj.customerName && obj.customerName.toLowerCase().includes(this.searchKey);

                if (outletMatch || codeMatch || nameMatch) {
                    searchedData.push(obj);
                    if (searchedData.length >= 50) break; // limit results
                }
            }

            this.dataViewItems = searchedData;
        } else {
            // reset to original list
            this.dataViewItems = [...this.AlldataViewItems];
        }
        this.getItemsWithIndex();
    }


    //Assign Button and Cancel
    handleAssignButtonClick()
    {
        this.isSubPartLoad = true;

        setTimeout(() => {
            this.isSubPartLoad = false;
        }, 1000); // 1 second delay
        this.viewScreen = false;
        this.showPreview = false;
        this.editScreen = true;
        this.relatedScustomers = this.sCustomerList ;
        this.OriginalRelatedScustomers = this.sCustomerList ;
        this.showCustomers = this.sCustomerList.length >0 ? true : false;
        this.selectedPrimaryCustomer = '';
        this.selectedSubStockiest = '';
    }
    handlecancel()
    {
        this.editScreen = false;
        this.showPreview = false;
        this.viewScreen = true;
    }

    // Handle Primary Customer Picklist Change
    handlePrimaryCustomerChange(event) {
        const selectedId = event.detail.value;
        this.selectedPrimaryCustomer = selectedId;
        this.selectedSubStockiest = '';
        this.OriginalRelatedScustomers = [];
        this.relatedScustomers = [];
        this.showCustomers = false;

        // Get customer type 
        const customerType = this.primaryCustomerWithCustomerTypeMap[selectedId] || '';
        this.isSuperStockiest = customerType === 'Superstockiest';

        if (this.isSuperStockiest) {
            // Get sub stockiests 
            const substockiests = this.primaryCustomerToSubStockiestMap[selectedId] || [];
            console.log('Substockiests:', JSON.stringify(substockiests));
            this.relatedSubStockiestOptions = this.getPicklistValuesWithCode(substockiests, 'Name', 'Id','customerCode');
        }

        this.getRelatedSCustomers(selectedId);
    }
    getRelatedSCustomers(selectedId) {
        if(selectedId)
        {
            this.relatedScustomers = this.OriginalsCustomerList.filter(pm => pm.primaryCustomerId === selectedId);
        }
        else
        {
            this.relatedScustomers = this.OriginalsCustomerList;
        }
        this.OriginalRelatedScustomers =  [...this.relatedScustomers];
        this.showCustomers = this.relatedScustomers.length > 0 ? true : false;
    }

    //Handler SubstoiestSelect
    handleSubstockiestCustomerChange(event)
    {
        const selectedId = event.detail.value;
        this.selectedSubStockiest = selectedId;
         if(selectedId)
        {
            this.relatedScustomers = this.OriginalsCustomerList.filter(pm => pm.parentSubStoickistId === selectedId);
        }
        else
        {
            this.relatedScustomers = this.OriginalsCustomerList.filter(pm => pm.primaryCustomerId === this.selectedPrimaryCustomer);
        }
        this.OriginalRelatedScustomers =  [...this.relatedScustomers];
        this.showCustomers = this.relatedScustomers.length > 0 ? true : false; 
    }
 

    //Add And Removed
    addData(event) {
        const compositekey = event.currentTarget.dataset.compositekey;

        // Update relatedScustomers
        this.relatedScustomers = this.relatedScustomers.map(cust => {
            if (cust.compositekey === compositekey) {
                return { ...cust, isSelected: true };
            }
            return cust;
        });

        // Update OriginalsCustomerList
        this.OriginalsCustomerList = this.OriginalsCustomerList.map(cust => {
            if (cust.compositekey === compositekey) {
                return { ...cust, isSelected: true };
            }
            return cust;
        });

        // Update OriginalRelatedScustomers (important for search sync)
        this.OriginalRelatedScustomers = this.OriginalRelatedScustomers.map(cust => {
            if (cust.compositekey === compositekey) {
                return { ...cust, isSelected: true };
            }
            return cust;
        });
    }
    removeData(event) {
        const compositekey = event.currentTarget.dataset.compositekey;

        // Find the removed customer in OriginalsCustomerList or relatedScustomers
        const removedCustomer = this.relatedScustomers.find(cust => cust.compositekey === compositekey);

        if (removedCustomer && removedCustomer.productMappingId) {
            // Add to delete list only if not already added
            if (!this.productMappingToDeleteList.includes(removedCustomer.productMappingId)) {
                this.productMappingToDeleteList.push(removedCustomer.productMappingId);
            }
        }
        // Update OriginalsCustomerList
        this.OriginalsCustomerList = this.OriginalsCustomerList.map(cust => {
            if (cust.compositekey === compositekey) {
                return { ...cust, isSelected: false };
            }
            return cust;
        });

        // Update relatedScustomers
        this.relatedScustomers = this.relatedScustomers.map(cust => {
            if (cust.compositekey === compositekey) {
                return { ...cust, isSelected: false };
            }
            return cust;
        });

         // Update OriginalRelatedScustomers
        this.OriginalRelatedScustomers = this.OriginalRelatedScustomers.map(cust => {
            if (cust.compositekey === compositekey) {
                return { ...cust, isSelected: false };
            }
            return cust;
        });
    }

    //Search Customers
    searchCustomers(event) {
        const searchValue = event.target.value.toLowerCase();
        this.searchedSecoundaryCustomer = searchValue; // If you want to keep the input synced

        if (!searchValue) {
            // If input is cleared, show full list
            this.relatedScustomers = [...this.OriginalRelatedScustomers];
        } else {
            // Otherwise, filter by name
            this.relatedScustomers = this.OriginalRelatedScustomers.filter(cust =>
                cust.customerName?.toLowerCase().includes(searchValue)
            );
        }
        this.showCustomers = this.relatedScustomers.length > 0 ? true : false;
    }

    //Preview Customers
    previewCustomers() {
        this.editScreen = false;
        this.viewScreen = false;
        this.showPreview = true;
        // Get only selected customers
        const selectedCustomers = this.OriginalsCustomerList.filter(cust => cust.isSelected);

        // Build payload
        this.previewCustomerList = selectedCustomers.map(cust => ({
            compositekey:cust.compositekey,
            productMappingId:cust.productMappingId,
            customerName: cust.customerName,
            customerId: cust.customerId,
            primaryCustomerId: cust.primaryCustomerId,
            primaryCustomerName: cust.primaryCustomerName,
            parentSubStoickistId: cust.parentSubStoickistId,
            parentSubstockiestName: cust.parentSubstockiestName,
            customerType: cust.customerType,
            isUnderSubStockiest:cust.isUnderSubStockiest,
            customerBussinessType: cust.customerBussinessType
        }));
        this.isPreviewDataExisted = this.previewCustomerList.length > 0 ? true : false;
        console.log('Preview Payload:', JSON.stringify(this.previewCustomerList));
    }

    handleback()
    {
        this.showPreview = false;
        this.viewScreen = false;
        this.editScreen = true;
    }
    handlesave()
    {
        if (!navigator.onLine) {
            this.isLoading = false;
            this.showToast('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        this.isSubPartLoad = true;
        if(this.previewCustomerList.length > 0)
        {
            const payload = this.previewCustomerList.map(item => {
                return {
                    sObjectType: 'Product_Mapping__c',
                    Id:item.productMappingId,
                    Exectuive__c: this.selectedUserId,
                    Employee__c : this.employeeId,
                    Customer__c: item.customerId,
                    Primary_Customer__c: item.primaryCustomerId,
                    Sub_Stockiest__c: item.parentSubStoickistId
                };
            });
            // Extract IDs from payload
            const payloadIds = new Set(payload.map(p => p.Id).filter(id => id));

            // Filter the delete list to remove any IDs that are also in the payload
            const filteredDeleteList = this.productMappingToDeleteList.filter(
                id => !payloadIds.has(id)
            );
            console.log('payload '+JSON.stringify(payload));

           saveProductMappings({ mappingList: payload,productMappingtoDelete : filteredDeleteList })
            .then(() => {
                this.assignedPrimaryCustomers =  [];
                this.sCustomerList = [];
                this.OriginalsCustomerList = [];
                this.dataViewItems = [];

                this.showPreview = false;
                this.editScreen = false;
          
                this.showToast('Success', 'Secoundary customer assignments saved successfully.', 'success');
                this.getAllData();
                this.viewScreen = true;
               
            })
            .catch(error => {
                this.showToast('Error', 'Error saving product mappings.', 'error');
                console.error('ERROR'+JSON.stringify(error));
            });
        }
        else
        {
            this.isSubPartLoad = false;
            this.showToast('Error', 'Please assign at least one customer before saving', 'error');
        }
    }

    /**Helper Methods */
    getPicklistValuesWithCode(optionsArray, labelField, valueField, codeField) {
        const picklist = optionsArray.map(option => {
            let label = option[labelField] || '';

            // If codeField is provided and value exists, append it
            if (codeField && option[codeField]) {
                label += ' (' + option[codeField] + ')';
            }

            return {
                label: label,
                value: option[valueField]
            };
        });

        // Add "All" option at the beginning
        return [{ label: 'All', value: '' }, ...picklist];
    }




    sortByName() {
        // Toggle sort direction
        this.sortDirection = this.sortDirection === 'asc' ? 'desc' : 'asc';

        this.relatedScustomers = [...this.relatedScustomers].sort((a, b) => {
            const nameA = a.customerName?.toLowerCase() || '';
            const nameB = b.customerName?.toLowerCase() || '';
            
            if (this.sortDirection === 'asc') {
                return nameA.localeCompare(nameB);
            } else {
                return nameB.localeCompare(nameA);
            }
        });
    }
    //Show Toast
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

}