// import { LightningElement, track } from 'lwc';
// import getAllProducts from '@salesforce/apex/DMSPortalLwc.getAllProducts'; // You need this Apex method
// import savePrimaryReturn from '@salesforce/apex/DMSPortalLwc.savePrimaryReturn';
// import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// export default class NewPrimaryReturn extends LightningElement {
//     @track returnItems = [];
//     @track productOptions = [];
//     returnReasonOptions = [
//         { label: 'Damaged', value: 'Damaged' },
//         { label: 'Expired', value: 'Expired' },
//         { label: 'Non-moving', value: 'Non-moving' }
//     ];

//     connectedCallback() {
//         this.addRow(); // Start with one row
//         getAllProducts().then(result => {
//             this.productOptions = result.map(prod => ({
//                 label: prod.Name,
//                 value: prod.Id,
//                 price: prod.List_Price__c,
//                 uom: prod.UOM__c
//             }));
//         }).catch(error => {
//             this.showToast('Error loading products', error.body.message, 'error');
//         });
//     }

//     addRow() {
//         this.returnItems = [
//             ...this.returnItems,
//             {
//                 id: Date.now(),
//                 productId: '',
//                 quantity: 1,
//                 unitPrice: 0,
//                 amount: 0,
//                 uom: '',
//                 reason: ''
//             }
//         ];
//     }

//     removeRow(event) {
//         const index = event.currentTarget.dataset.index;
//         this.returnItems.splice(index, 1);
//         this.returnItems = [...this.returnItems];
//     }

//     handleProductChange(event) {
//         const index = event.target.dataset.index;
//         const selectedId = event.detail.value;
//         const selectedProduct = this.productOptions.find(p => p.value === selectedId);
//         const updatedItem = this.returnItems[index];

//         updatedItem.productId = selectedId;
//         updatedItem.unitPrice = selectedProduct?.price || 0;
//         updatedItem.uom = selectedProduct?.uom || '';
//         updatedItem.amount = updatedItem.quantity * updatedItem.unitPrice;

//         this.returnItems = [...this.returnItems];
//     }

//     handleQuantityChange(event) {
//         const index = event.target.dataset.index;
//         const qty = parseFloat(event.detail.value);
//         const item = this.returnItems[index];

//         item.quantity = qty;
//         item.amount = qty * item.unitPrice;
//         this.returnItems = [...this.returnItems];
//     }

//     handleReasonChange(event) {
//         const index = event.target.dataset.index;
//         this.returnItems[index].reason = event.detail.value;
//     }

//     handleSave() {
//         const payload = this.returnItems.map(item => ({
//             productId: item.productId,
//             Quantity__c: item.quantity,
//             returnReason: item.reason
//         }));

//         if (payload.length === 0 || payload.some(p => !p.productId || !p.quantity || !p.returnReason)) {
//             this.showToast('Validation Error', 'Please fill all required fields.', 'error');
//             return;
//         }

//         savePrimaryReturn({ items: payload })
//             .then(() => {
//                 this.showToast('Success', 'Primary Return saved successfully', 'success');
//                 this.dispatchEvent(new CustomEvent('returncreated'));
//             })
//             .catch(error => {
//                 this.showToast('Error', error.body?.message || 'Unknown error', 'error');
//             });
//     }

//     handleCancel() {
//         this.dispatchEvent(new CustomEvent('cancel'));
//     }

//     showToast(title, message, variant) {
//         this.dispatchEvent(new ShowToastEvent({
//             title,
//             message,
//             variant
//         }));
//     }
// }





// import { LightningElement, track } from 'lwc';
// import getAllProducts from '@salesforce/apex/DMSPortalLwc.getAllProducts';
// import savePrimaryReturn from '@salesforce/apex/DMSPortalLwc.savePrimaryReturn';
// import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// export default class NewPrimaryReturn extends LightningElement {
//     @track returnItems = [{
//         id: Date.now(),
//         productId: '',
//         productName: '',
//         quantity: 0,
//         unitPrice: 0,
//         amount: 0,
//         uom: '',
//         reason: '',
//         showSuggestions: false,
//         filteredProducts: []
//     }];
//     @track productOptions = [];

//     returnReasonOptions = [
//         { label: 'Damaged', value: 'Damaged' },
//         { label: 'Expired', value: 'Expired' },
//         { label: 'Non-moving', value: 'Non-moving' }
//     ];

//     @track totalQuantity = 0;
//     @track totalAmount = 0;

//     connectedCallback() {
//         getAllProducts()
//             .then(result => {
//                 this.productOptions = result.map(prod => ({
//                     label: prod.Name,
//                     value: prod.Id,
//                     price: prod.List_Price__c,
//                     uom: prod.UOM__c
//                 }));
//             })
//             .catch(error => {
//                 this.showToast('Error loading products', error.body.message, 'error');
//             });
//     }

//     addRow() {
//         this.returnItems = [
//             ...this.returnItems,
//             {
//                 id: Date.now(),
//                 productId: '',
//                 productName: '',
//                 quantity: 0,
//                 unitPrice: 0,
//                 amount: 0,
//                 uom: '',
//                 reason: '',
//                 showSuggestions: false,
//                 filteredProducts: []
//             }
//         ];
//         this.calculateTotals();
//     }

//     removeRow(event) {
//         const index = Number(event.currentTarget.dataset.index);
    
//         if (this.returnItems.length === 1) {
//             // Reset the only remaining row instead of removing it
//             this.returnItems = [{
//                 id: Date.now(),
//                 productId: '',
//                 productName: '',
//                 quantity: 0,
//                 unitPrice: 0,
//                 amount: 0,
//                 uom: '',
//                 reason: '',
//                 showSuggestions: false,
//                 filteredProducts: []
//             }];
//             this.calculateTotals();
            
//         } else {
//             this.returnItems.splice(index, 1);
//             this.returnItems = [...this.returnItems];
//             this.calculateTotals();
//         }
//     }
    

//     handleProductFocus(event) {
//         const index = event.target.dataset.index;
//         const item = this.returnItems[index];
//         item.showSuggestions = false; // Don't show on focus, only on search
//         this.returnItems = [...this.returnItems];
//     }

//     handleProductSearch(event) {
//         const index = event.target.dataset.index;
//         const searchValue = event.target.value.toLowerCase();
//         const item = this.returnItems[index];
//         item.productName = event.target.value;

//         if (searchValue.length > 0) {
//             const filtered = this.productOptions.filter(prod =>
//                 prod.label.toLowerCase().includes(searchValue)
//             );
//             item.filteredProducts = filtered;
//             item.showSuggestions = filtered.length > 0;
//         } else {
//             item.filteredProducts = [];
//             item.showSuggestions = false;
//         }

//         this.returnItems = [...this.returnItems];
//     }

//     selectProduct(event) {
//         const index = event.currentTarget.dataset.index;
//         const selectedId = event.currentTarget.dataset.id;
//         const selectedProduct = this.productOptions.find(p => p.value === selectedId);

//         // Prevent duplicate selection
//         const isDuplicate = this.returnItems.some((item, i) =>
//             i !== parseInt(index) && item.productId === selectedId
//         );
//         if (isDuplicate) {
//             this.showToast('Error', `Product "${selectedProduct.label}" already selected`, 'error');
//             this.returnItems[index].productName = '';
//             this.returnItems[index].showSuggestions = false;
//             return;
//         }

//         const item = this.returnItems[index];
//         item.productId = selectedId;
//         item.productName = selectedProduct.label;
//         item.unitPrice = selectedProduct.price;
//         item.uom = selectedProduct.uom;
//         item.amount = item.quantity * item.unitPrice;
//         item.showSuggestions = false;
//         item.filteredProducts = [];

//         this.returnItems = [...this.returnItems];
//         this.calculateTotals();
//     }

//     handleQuantityChange(event) {
//         const index = event.currentTarget.dataset.index;
//         const qty = parseFloat(event.detail.value) || 0;
//         const item = this.returnItems[index];
//         item.quantity = qty;
//         item.amount = qty * item.unitPrice;
//         this.returnItems = [...this.returnItems];
//         this.calculateTotals();
//     }

//     handleReasonChange(event) {
//         const index = event.currentTarget.dataset.index;
//         this.returnItems[index].reason = event.detail.value;
//     }

//     calculateTotals() {
//         this.totalQuantity = this.returnItems.reduce((acc, item) => acc + (item.quantity || 0), 0);
//         this.totalAmount = this.returnItems.reduce((acc, item) => acc + (item.amount || 0), 0);
//     }

//     handleSave() {
//         const payload = [];
    
//         for (let item of this.returnItems) {
//             if (!item.productId || item.quantity === 0 || !item.reason) {
//                 this.showToast('Validation Error', 'Please fill all required fields.', 'error');
//                 return;
//             }
    
//             payload.push({
//                 sobjectType: 'Primary_Return_Item__c',
//                 Product__c: item.productId,
//                 Quantity__c: item.quantity,
//                 unit_price__c: item.unitPrice,
//                 UOM__c: item.uom,
//                 Amount__c: item.amount,

//                 Return_Reason__c: item.reason
//             });
//         }
    
//         console.log('Payload:', JSON.stringify(payload));
    
//         savePrimaryReturn({ items: payload,TotalQuantity:this.totalQuantity,TotalAmount:this.totalAmount })
//             .then(() => {
//                 this.showToast('Success', 'Primary Return saved successfully', 'success');
//                 const successEvent = new CustomEvent('returncreated', {
//                     detail: { totalQuantity: this.totalQuantity, totalAmount: this.totalAmount }
//                 });
//                 this.dispatchEvent(successEvent);
//             })
//             .catch(error => {
//                 this.showToast('Error', error.body?.message || 'Unknown error', 'error');
//             });
//     }

//     handleCancel() {
//         this.dispatchEvent(new CustomEvent('cancel'));
//     }

//     showToast(title, message, variant) {
//         this.dispatchEvent(
//             new ShowToastEvent({
//                 title,
//                 message,
//                 variant
//             })
//         );
//     }
// }





import { LightningElement, track } from 'lwc';
import getAllProducts from '@salesforce/apex/DMSPortalLwc.getAllProducts';
import savePrimaryReturn from '@salesforce/apex/DMSPortalLwc.savePrimaryReturn';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class NewPrimaryReturn extends LightningElement {
    @track returnItems = [{
        id: Date.now(),
        productId: '',
        productName: '',
        quantity: 0,
        unitPrice: 0,
        amount: 0,
        uom: '',
        reason: '',
        showSuggestions: false,
        filteredProducts: []
    }];
    @track productOptions = [];

    returnReasonOptions = [
        { label: 'Damaged', value: 'Damaged' },
        { label: 'Expired', value: 'Expired' },
        { label: 'Non-moving', value: 'Non-moving' }
    ];

    @track totalQuantity = 0;
    @track totalAmount = 0;

    connectedCallback() {
        getAllProducts()
            .then(result => {
                this.productOptions = result.map(prod => ({
                    label: prod.Name,
                    value: prod.Id,
                    price: prod.List_Price__c,
                    uom: prod.UOM__c
                }));
            })
            .catch(error => {
                this.showToast('Error loading products', error.body.message, 'error');
            });
    }

    addRow() {
        this.returnItems = [
            ...this.returnItems,
            {
                id: Date.now(),
                productId: '',
                productName: '',
                quantity: 0,
                unitPrice: 0,
                amount: 0,
                uom: '',
                reason: '',
                showSuggestions: false,
                filteredProducts: []
            }
        ];
        this.calculateTotals();
    }

    removeRow(event) {
        const index = Number(event.currentTarget.dataset.index);
    
        if (this.returnItems.length === 1) {
            // Reset the only remaining row instead of removing it
            this.returnItems = [{
                id: Date.now(),
                productId: '',
                productName: '',
                quantity: 0,
                unitPrice: 0,
                amount: 0,
                uom: '',
                reason: '',
                showSuggestions: false,
                filteredProducts: []
            }];
            this.calculateTotals();
        } else {
            this.returnItems.splice(index, 1);
            this.returnItems = [...this.returnItems];
            this.calculateTotals();
        }
    }
    

    handleProductFocus(event) {
        const index = event.target.dataset.index;
        const item = this.returnItems[index];
        item.showSuggestions = false; // Don't show on focus, only on search
        this.returnItems = [...this.returnItems];
    }

 handleProductSearch(event) {
    const index = event.target.dataset.index;
    const searchValue = event.target.value.toLowerCase();
    const item = this.returnItems[index];
    item.productName = event.target.value;  // Update product name on search input

    if (searchValue.length > 0) {
        // Filter products based on search input
        const filtered = this.productOptions.filter(prod =>
            prod.label.toLowerCase().includes(searchValue)
        );
        item.filteredProducts = filtered;
        item.showSuggestions = filtered.length > 0;
    } else {
        // If the search input is cleared, reset the product and hide suggestions
        item.filteredProducts = [];
        item.showSuggestions = false;
        item.productId = '';  // Clear the productId when cross is clicked
        item.productName = '';  // Clear the productName
        item.unitPrice = 0;  // Reset unitPrice
        item.uom = '';  // Reset UOM
        item.amount = 0;  // Reset amount
    }

    this.returnItems = [...this.returnItems];  // Trigger re-render of the list
    this.calculateTotals();  // Recalculate totals
}

    selectProduct(event) {
        const index = event.currentTarget.dataset.index;
        const selectedId = event.currentTarget.dataset.id;
        const selectedProduct = this.productOptions.find(p => p.value === selectedId);

        // Prevent duplicate selection
        const isDuplicate = this.returnItems.some((item, i) =>
            i !== parseInt(index) && item.productId === selectedId
        );
        if (isDuplicate) {
             const productLabel = selectedProduct.label || 'Unknown Product'; // Fallback value

this.showToast('Error', 'Product "' + productLabel + '" already selected', 'error');
            this.returnItems[index].productName = '';
            this.returnItems[index].showSuggestions = false;
            return;
        }

        const item = this.returnItems[index];
        item.productId = selectedId;
        item.productName = selectedProduct.label;
        item.unitPrice = selectedProduct.price;
        item.uom = selectedProduct.uom;
        item.amount = item.quantity * item.unitPrice;
        item.showSuggestions = false;
        item.filteredProducts = [];

        this.returnItems = [...this.returnItems];
        this.calculateTotals();
    }

    handleQuantityChange(event) {
        const index = event.currentTarget.dataset.index;
        const qty = parseFloat(event.detail.value) || 0;
        const item = this.returnItems[index];
        item.quantity = qty;
        item.amount = qty * item.unitPrice;
        this.returnItems = [...this.returnItems];
        this.calculateTotals();
    }

    handleReasonChange(event) {
        const index = event.currentTarget.dataset.index;
        this.returnItems[index].reason = event.detail.value;
    }

    calculateTotals() {
        this.totalQuantity = this.returnItems.reduce((acc, item) => acc + (item.quantity || 0), 0);
        this.totalAmount = this.returnItems.reduce((acc, item) => acc + (item.amount || 0), 0);
    }

    handleSave() {
        const payload = [];
    
        for (let item of this.returnItems) {
         

                const missingProduct2 = this.returnItems.find(item => !item.productId);
        if (missingProduct2) {
            this.showToast('Validation Error', 'Please select a Product for all rows.', 'error');
            return;
        }

          const missingProduct4 = this.returnItems.find(item => !item.quantity > 0 );
        if (missingProduct4) {
            this.showToast('Validation Error', 'Please select valid Quantity for all rows .', 'error');
            return;
        }

               const missingProduct3 = this.returnItems.find(item => !item.reason);
        if (missingProduct3) {
            this.showToast('Validation Error', 'Please select a Reason for all rows.', 'error');
            return;
        }

       

       

         
    
            payload.push({
                sobjectType: 'Primary_Return_Item__c',
                Product__c: item.productId,
                Quantity__c: item.quantity,
                unit_price__c: item.unitPrice,
                UOM__c: item.uom,
                Amount__c: item.amount,
                Return_Reason__c: item.reason
            });
        }

         const PrimaryReturn = {
        sobjectType: 'Primary_Return__c',
        // Customer__c: this.customerId,
        // Order__c: this.orderId,
        // Total_Quantity__c:
       
    };
    
        console.log('Payload:', JSON.stringify(payload));
    
        // savePrimaryReturn({ items: payload, TotalQuantity: this.totalQuantity, TotalAmount: this.totalAmount })
        //     .then(() => {
        //         this.showToast('Success', 'Primary Return saved successfully', 'success');
        //          setTimeout(() => {
                // this.dispatchEvent(new CustomEvent('returncreated', {
                //     detail: { totalQuantity: this.totalQuantity, totalAmount: this.totalAmount }
                //     }));
               
        //     }, 1000);
        //          this.resetForm();
        //     })
        //   .catch((error) => {
        //     console.error('Error:', error);
        //     this.showToast('Failed to create return', 'error');
        // });

         savePrimaryReturn({PrimaryReturn,items: payload , TotalQuantity: this.totalQuantity, TotalAmount: this.totalAmount })
                .then((result) => {
                    console.log('Return saved:', result);
                    this.showToast('success','Return created successfully.', 'success');
                    setTimeout(() => {
                                this.dispatchEvent(new CustomEvent('returncreated', {
                    detail: { totalQuantity: this.totalQuantity, totalAmount: this.totalAmount }
                    }));
                        this.resetForm();
                        
                    }, 1000);
                })
                .catch((error) => {
                    console.error('Error:', error);
                    this.showToast('Failed to create return', 'error');
                });
    }

    handleCancel() {
        this.dispatchEvent(new CustomEvent('cancel'));
    }

    // Custom Toast method
    showToast(title, message, variant) {
        const toast = this.template.querySelector('c-custom-toast'); // Query the toast component
        console.log('Custom Toast component:', toast);  // Log the reference

        if (toast) {
            toast.showToast(variant, message); // Show the toast with the correct variant
        } else {
            console.error('Custom Toast component not found!');
        }
    }
}