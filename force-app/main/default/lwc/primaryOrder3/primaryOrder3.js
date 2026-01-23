// import { LightningElement, track, wire } from 'lwc';
// import getAllProducts from '@salesforce/apex/primaryorderTABLEVIEW.getAllProducts';
// import savePrimaryOrder from '@salesforce/apex/primaryorderTABLEVIEW.savePrimaryOrder';
// import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// export default class PrimaryOrder3 extends LightningElement {
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

//     @track totalQuantity = 0;
//     @track totalAmount = 0;
//     @track ShowAll = true;
//     @track showSummary = false;

//     // Load products
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
//                 showSuggestions: false,
//                 filteredProducts: []
//             }
//         ];
//         this.calculateTotals();
//     }

//     removeRow(event) {
//         const index = Number(event.currentTarget.dataset.index);

//         if (this.returnItems.length === 1) {
//             this.returnItems = [{
//                 id: Date.now(),
//                 productId: '',
//                 productName: '',
//                 quantity: 0,
//                 unitPrice: 0,
//                 amount: 0,
            
               
//                 showSuggestions: false,
//                 filteredProducts: []
//             }];
//         } else {
//             this.returnItems.splice(index, 1);
//         }
//         this.returnItems = [...this.returnItems];
//         this.calculateTotals();
//     }

//     handleProductFocus(event) {
//         const index = event.target.dataset.index;
//         const item = this.returnItems[index];
//         item.showSuggestions = false;
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

//     handleNext() {



        
//         if (this.returnItems.some(item => item.productId && item.quantity > 0)) {
//             this.ShowAll = false;
//             this.showSummary = true;
//         } else {
//             this.showToast('Validation Error', 'Please select at least one product.', 'error');
//         }
//     }

//     // Get the summary items (filter only selected items with quantities)
//     get summaryItems() {
//         return this.returnItems
//             .filter(item => item.productId && item.quantity > 0) // Only include selected products
//             .map(item => ({
//                 id: item.productId,
//                 name: item.productName,
//                 quantity: item.quantity,
//                 price: item.unitPrice,
//                 priceFormatted: this.formatCurrency(item.unitPrice),
//                 total: item.quantity * item.unitPrice,
//                 totalFormatted: this.formatCurrency(item.quantity * item.unitPrice)
//             }));
//     }

//     get grandTotalFormatted() {
//         const total = this.summaryItems.reduce((sum, item) => sum + item.total, 0);
//         return this.formatCurrency(total);
//     }

//     handleBack() {
//         this.showSummary = false;
//         this.ShowAll = true;
//     }

//     handleSave() {
//     const payload = [];

//     // Iterate over the summary items (the selected products with valid quantities)
//     for (let item of this.summaryItems) {
//         // Validate the required fields before pushing to the payload
//         if (!item.productId || item.quantity <= 0 || !item.reason) {
//             this.showToast('Validation Error', 'Please fill all required fields for all selected products.', 'error');
//             return;
//         }

//         // Prepare the payload for each order item
//         payload.push({
//             sobjectType: 'Order_Item__c',
//             Product__c: item.productId, // Use productId for the selected product
//             Quantity__c: item.quantity,
//             Unit_Price__c: item.price, // Assuming 'price' is from summaryItems
//             Total_Amount__c: item.total, // Calculate total based on quantity and price
           
//         });
//     }

//     // If there are no valid order items, exit the function
//     if (payload.length === 0) {
//         this.showToast('Validation Error', 'No valid items to save.', 'error');
//         return;
//     }

//     // Log the payload for debugging purposes
//     console.log('Payload:', JSON.stringify(payload));

//     // Call the Apex method to save the order and items
//     savePrimaryOrder({ items: payload, TotalQuantity: this.totalQuantity, TotalAmount: this.totalAmount })
//         .then(() => {
//             this.showToast('Success', 'Primary Order saved successfully', 'success');
//             const successEvent = new CustomEvent('ordercreated', {
//                 detail: { totalQuantity: this.totalQuantity, totalAmount: this.totalAmount }
//             });
//             this.dispatchEvent(successEvent);
//         })
//         .catch(error => {
//             this.showToast('Error', error.body?.message || 'Unknown error', 'error');
//         });
// }


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

//     formatCurrency(amount) {
//         return new Intl.NumberFormat('en-IN', {
//             style: 'currency',
//             currency: 'INR'
//         }).format(amount);
//     }
// }




// import { LightningElement, track } from 'lwc';
// import getAllProducts from '@salesforce/apex/primaryorderTABLEVIEW.getAllProducts';
// import savePrimaryOrder from '@salesforce/apex/DMSPortalLwc.savePrimaryOrder';
// import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// export default class PrimaryOrder3 extends LightningElement {
//     @track invalidFields = {};
//     @track orderItems = [{
//         id: Date.now(),
//         productId: '',
//         productName: '',
//         quantity: 0,
//         unitPrice: 0,
//         amount: 0,
//         taxpercent: 0,
//         taxAmount: 0,
//         showSuggestions: false,
//         filteredProducts: []
//     }];
//     @track productOptions = [];

//     @track totalQuantity = 0;
//     @track totalAmount = 0;
//     @track totalTax = 0;
//     @track ShowAll = true;
//     @track showSummary = false;

//     connectedCallback() {
//         getAllProducts()
//             .then(result => {
//                 this.productOptions = result.map(prod => ({
//                     label: prod.Name,
//                     value: prod.Id,
//                     price: prod.List_Price__c,
//                     taxpercent: prod.Tax_Class__c,
//                     uom: prod.UOM__c
//                 }));
//             })
//             .catch(error => {
//                 this.showToast('Error loading products', error.body.message, 'error');
//             });
//     }

//     addRow() {
//         this.orderItems = [
//             ...this.orderItems,
//             {
//                 id: Date.now(),
//                 productId: '',
//                 productName: '',
//                 quantity: 0,
//                 unitPrice: 0,
//                 amount: 0,
//                 taxpercent: 0,
//                 taxAmount: 0,
//                 showSuggestions: false,
//                 filteredProducts: []
//             }
//         ];
//         this.calculateTotals();
//     }

//     removeRow(event) {
//         const index = Number(event.currentTarget.dataset.index);
//         if (this.orderItems.length === 1) {
//             this.orderItems = [{
//                 id: Date.now(),
//                 productId: '',
//                 productName: '',
//                 quantity: 0,
//                 unitPrice: 0,
//                 amount: 0,
//                 taxpercent: 0,
//                 taxAmount: 0,
//                 showSuggestions: false,
//                 filteredProducts: []
//             }];
//         } else {
//             this.orderItems.splice(index, 1);
//         }
//         this.orderItems = [...this.orderItems];
//         this.calculateTotals();
//     }

//     handleProductFocus(event) {
//         const index = event.target.dataset.index;
//         this.orderItems[index].showSuggestions = false;
//         this.orderItems = [...this.orderItems];
//     }

//     handleProductSearch(event) {
//         const index = event.target.dataset.index;
//         const searchValue = event.target.value.toLowerCase();
//         const item = this.orderItems[index];
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

//         this.orderItems = [...this.orderItems];
//     }

//     selectProduct(event) {
//         const index = event.currentTarget.dataset.index;
//         const selectedId = event.currentTarget.dataset.id;
//         const selectedProduct = this.productOptions.find(p => p.value === selectedId);

//         const isDuplicate = this.orderItems.some((item, i) =>
//             i !== parseInt(index) && item.productId === selectedId
//         );
//         if (isDuplicate) {
//             this.showToast('Error', `Product "${selectedProduct.label}" already selected`, 'error');
//             const item = this.orderItems[index];
//             item.productName = '';
//             item.productId = '';
//             item.unitPrice = 0;
//             item.amount = 0;
//             item.taxpercent = 0;
//             item.taxAmount = 0;
//             item.showSuggestions = false;
//             item.filteredProducts = [];
//             this.orderItems = [...this.orderItems];
//             this.calculateTotals();
//             return;
//         }

//         const item = this.orderItems[index];
//         item.productId = selectedId;
//         item.productName = selectedProduct.label;
//         item.unitPrice = selectedProduct.price;
//         item.taxpercent = selectedProduct.taxpercent || 0;

//         const baseAmount = item.quantity * item.unitPrice;
//         item.taxAmount = (baseAmount * item.taxpercent) / 100;
//         item.amount = baseAmount + item.taxAmount;

//         item.showSuggestions = false;
//         item.filteredProducts = [];

//         // Hide suggestion dropdown
//         const input = this.template.querySelector(`[data-index="${index}"]`);
//         if (input) input.blur();

//         this.orderItems = [...this.orderItems];
//         this.calculateTotals();
//     }

//     handleQuantityChange(event) {
//         const index = event.currentTarget.dataset.index;
//         const qty = parseFloat(event.detail.value) || 0;
//         const item = this.orderItems[index];
//         item.quantity = qty;

//         const baseAmount = qty * item.unitPrice;
//         item.taxAmount = (baseAmount * item.taxpercent) / 100;
//         item.amount = baseAmount + item.taxAmount;

//         this.orderItems = [...this.orderItems];
//         this.calculateTotals();
//     }

//     calculateTotals() {
//         this.totalQuantity = this.validOrderItems.reduce((acc, item) => acc + (item.quantity || 0), 0);
//         this.totalAmount = this.validOrderItems.reduce((acc, item) => acc + (item.amount || 0), 0);
//         this.totalTax = this.validOrderItems.reduce((acc, item) => acc + (item.taxAmount || 0), 0);
//     }

//     get validOrderItems() {
//         return this.orderItems.filter(item => item.productId && item.quantity > 0);
//     }

//     handleNext() {
//         const anyProductSelected = this.orderItems.some(item => item.productId);
//         if (!anyProductSelected) {
//             this.showToast('Validation Error', 'Please select at least one product.', 'error');
//             return;
//         }

//         const missingProduct = this.orderItems.find(item => item.quantity > 0 && !item.productId);
//         if (missingProduct) {
//             this.showToast('Validation Error', 'Please select a product for all rows with quantity.', 'error');
//             return;
//         }

//         const invalidQuantity = this.orderItems.find(item => item.productId && (item.quantity <= 0));
//         if (invalidQuantity) {
//             this.showToast('Validation Error', 'Please enter a valid quantity greater than zero for all selected products.', 'error');
//             return;
//         }

//         this.ShowAll = false;
//         this.showSummary = true;
//     }

//     get summaryItems() {
//         return this.validOrderItems.map(item => ({
//             id: item.productId,
//             name: item.productName,
//             quantity: item.quantity,
//             price: item.unitPrice,
//             taxpercent: item.taxpercent,
//             taxAmount: item.taxAmount,
//             priceFormatted: this.formatCurrency(item.unitPrice),
//             total: item.amount,
//             totalFormatted: this.formatCurrency(item.amount),
//             taxFormatted: this.formatCurrency(item.taxAmount)
//         }));
//     }

//     get grandTotalFormatted() {
//         const total = this.summaryItems.reduce((sum, item) => sum + item.total, 0);
//         return this.formatCurrency(total);
//     }

//     handleBack() {
//         this.showSummary = false;
//         this.ShowAll = true;
//     }

//     handleSave() {
//         if (this.validOrderItems.length === 0) {
//             this.showToast('Validation Error', 'No valid items to save.', 'error');
//             return;
//         }

//         const order = {
//             sobjectType: 'Order__c'
//         };

//         const payload = this.validOrderItems.map(item => ({
//             sobjectType: 'Order_Item__c',
//             Product__c: item.productId,
//             Quantity__c: item.quantity,
//             Unit_Price__c: item.unitPrice,
//             Tax_Percent__c: item.taxpercent,
//             Tax_Amount__c: item.taxAmount
//         }));

//         savePrimaryOrder({ order: order, items: payload })
//             .then(() => {
//                 this.showToast('Success', 'Primary Order saved successfully', 'success');
                // this.dispatchEvent(new CustomEvent('ordercreated', {
                //     detail: { totalQuantity: this.totalQuantity, totalAmount: this.totalAmount }
                // }));
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

//     formatCurrency(amount) {
//         return new Intl.NumberFormat('en-IN', {
//             style: 'currency',
//             currency: 'INR'
//         }).format(amount);
//     }
// }














import { LightningElement, track } from 'lwc';
import getAllProducts from '@salesforce/apex/primaryorderTABLEVIEW.getAllProducts';
import savePrimaryOrder from '@salesforce/apex/DMSPortalLwc.savePrimaryOrder';

export default class PrimaryOrder3 extends LightningElement {
    @track invalidFields = {};
    @track orderItems = [{
        id: Date.now(),
        productId: '',
        productName: '',
        quantity: 0,
        unitPrice: 0,
        amount: 0,
        taxpercent: 0,
        taxAmount: 0,
        showSuggestions: false,
        filteredProducts: []
    }];
    @track productOptions = [];

    @track totalQuantity = 0;
    @track totalAmount = 0;
    @track totalTax = 0;
    @track ShowAll = true;
    @track showSummary = false;

    connectedCallback() {
        getAllProducts()
            .then(result => {
                this.productOptions = result.map(prod => ({
                    label: prod.Name,
                    value: prod.Id,
                    price: prod.List_Price__c,
                    taxpercent: prod.Tax_Class__c,
                    uom: prod.UOM__c
                }));
            })
            .catch(error => {
                this.showToast('Error loading products', error.body.message, 'error');
            });
    }

    addRow() {
        this.orderItems = [
            ...this.orderItems,
            {
                id: Date.now(),
                productId: '',
                productName: '',
                quantity: 0,
                unitPrice: 0,
                amount: 0,
                taxpercent: 0,
                taxAmount: 0,
                showSuggestions: false,
                filteredProducts: []
            }
        ];
        this.calculateTotals();
    }

    removeRow(event) {
        const index = Number(event.currentTarget.dataset.index);
        if (this.orderItems.length === 1) {
            this.orderItems = [{
                id: Date.now(),
                productId: '',
                productName: '',
                quantity: 0,
                unitPrice: 0,
                amount: 0,
                taxpercent: 0,
                taxAmount: 0,
                showSuggestions: false,
                filteredProducts: []
            }];
        } else {
            this.orderItems.splice(index, 1);
        }
        this.orderItems = [...this.orderItems];
        this.calculateTotals();
    }

    handleProductFocus(event) {
        const index = event.target.dataset.index;
        this.orderItems[index].showSuggestions = false;
        this.orderItems = [...this.orderItems];
    }

 handleProductSearch(event) {
    const index = event.target.dataset.index;  // Get the index of the current row
    const searchValue = event.target.value.toLowerCase();  // Get the search value
    const item = this.orderItems[index];  // Get the current row item
    item.productName = event.target.value;  // Update the product name

    if (searchValue.length > 0) {
        // Filter products based on search input
        const filtered = this.productOptions.filter(prod =>
            prod.label.toLowerCase().includes(searchValue)  // Filter products based on search input
        );
        item.filteredProducts = filtered;
        item.showSuggestions = filtered.length > 0;
    } else {
        // If search is cleared (cross icon clicked), reset product-related fields
        item.filteredProducts = [];
        item.showSuggestions = false;
        item.productId = '';  // Clear the productId
        item.productName = '';  // Clear the productName
        item.unitPrice = 0;  // Reset unit price
        item.uom = '';  // Reset UOM
        item.amount = 0;  // Reset amount
    }

    this.orderItems = [...this.orderItems];  // Re-render the list
    this.calculateTotals();  // Recalculate totals
}


    selectProduct(event) {
        const index = event.currentTarget.dataset.index;
        const selectedId = event.currentTarget.dataset.id;
        const selectedProduct = this.productOptions.find(p => p.value === selectedId);

        const isDuplicate = this.orderItems.some((item, i) =>
            i !== parseInt(index) && item.productId === selectedId
        );
        if (isDuplicate) {
            const productLabel = selectedProduct.label || 'Unknown Product'; // Fallback value

this.showToast('Error', 'Product "' + productLabel + '" already selected', 'error');
          
            const item = this.orderItems[index];
            item.productName = '';
            item.productId = '';
            item.unitPrice = 0;
            item.amount = 0;
            item.taxpercent = 0;
            item.taxAmount = 0;
            item.showSuggestions = false;
            item.filteredProducts = [];
            this.orderItems = [...this.orderItems];
            this.calculateTotals();
            return;
        }

        const item = this.orderItems[index];
        item.productId = selectedId;
        item.productName = selectedProduct.label;
        item.unitPrice = selectedProduct.price;
        item.taxpercent = selectedProduct.taxpercent || 0;

        const baseAmount = item.quantity * item.unitPrice;
        item.taxAmount = (baseAmount * item.taxpercent) / 100;
        item.amount = baseAmount + item.taxAmount;

        item.showSuggestions = false;
        item.filteredProducts = [];

        // Hide suggestion dropdown
        const input = this.template.querySelector(`[data-index="${index}"]`);
        if (input) input.blur();

        this.orderItems = [...this.orderItems];
        this.calculateTotals();
    }

    handleQuantityChange(event) {
        const index = event.currentTarget.dataset.index;
        const qty = parseFloat(event.detail.value) || 0;
        const item = this.orderItems[index];
        item.quantity = qty;

        const baseAmount = qty * item.unitPrice;
        item.taxAmount = (baseAmount * item.taxpercent) / 100;
        item.amount = baseAmount + item.taxAmount;

        this.orderItems = [...this.orderItems];
        this.calculateTotals();
    }

    calculateTotals() {
        this.totalQuantity = this.validOrderItems.reduce((acc, item) => acc + (item.quantity || 0), 0);
        this.totalAmount = this.validOrderItems.reduce((acc, item) => acc + (item.amount || 0), 0);
        this.totalTax = this.validOrderItems.reduce((acc, item) => acc + (item.taxAmount || 0), 0);
    }

    get validOrderItems() {
        return this.orderItems.filter(item => item.productId && item.quantity > 0);
    }

    handleNext() {
        const anyProductSelected = this.orderItems.some(item => item.productId);
      

          const missingProduct2 = this.orderItems.find(item => !item.productId);
        if (missingProduct2) {
            this.showToast('Validation Error', 'Please select a product for all rows.', 'error');
            return;
        }

        const missingProduct = this.orderItems.find(item => !item.quantity > 0 );
        if (missingProduct) {
            this.showToast('Validation Error', 'Please select a valid quantity for all rows.', 'error');
            return;
        }

       

       

       

        this.ShowAll = false;
        this.showSummary = true;
    }

    get summaryItems() {
        return this.validOrderItems.map(item => ({
            id: item.productId,
            name: item.productName,
            quantity: item.quantity,
            price: item.unitPrice,
            taxpercent: item.taxpercent,
            taxAmount: item.taxAmount,
            priceFormatted: this.formatCurrency(item.unitPrice),
            total: item.amount,
            totalFormatted: this.formatCurrency(item.amount),
            taxFormatted: this.formatCurrency(item.taxAmount)
        }));
    }

    get grandTotalFormatted() {
        const total = this.summaryItems.reduce((sum, item) => sum + item.total, 0);
        return this.formatCurrency(total);
    }

    handleBack() {
        this.showSummary = false;
        this.ShowAll = true;
    }

    handleSave() {
      

        const order = {
            sobjectType: 'Order__c'
        };

        const payload = this.validOrderItems.map(item => ({
            sobjectType: 'Order_Item__c',
            Product__c: item.productId,
            Quantity__c: item.quantity,
            Unit_Price__c: item.unitPrice,
            Tax_Percent__c: item.taxpercent,
            Tax_Amount__c: item.taxAmount
        }));

       
             
          savePrimaryOrder({ order, items: payload })
               .then((result) => {
                   console.log('Order saved:', result);
                   this.showToast('Order created.','Order created successfully.', 'success');
                   setTimeout(() => {
                                      this.dispatchEvent(new CustomEvent('ordercreated', {
                    detail: { totalQuantity: this.totalQuantity, totalAmount: this.totalAmount }
                }));
                       this.resetForm();
                   }, 1000);
               })
               .catch((error) => {
                   console.error('Error:', error);
                   this.showToast('Failed to create order', 'error');
               });
    }

    handleCancel() {
        this.dispatchEvent(new CustomEvent('cancel'));
    }

    showToast(title, message, variant) {
        const toast = this.template.querySelector('c-custom-toast'); // Query the toast component
        console.log('Custom Toast component:', toast);  // Log the reference

        if (toast) {
            toast.showToast(variant, message); // Show the toast
        } else {
            console.error('Custom Toast component not found!');
        }
    }

    formatCurrency(amount) {
        return new Intl.NumberFormat('en-IN', {
            style: 'currency',
            currency: 'INR'
        }).format(amount);
    }
}