// import { LightningElement, track, wire } from 'lwc';
// import getActiveProducts from '@salesforce/apex/DMSPortalLwc.getActiveProducts';
// import getProductCategories from '@salesforce/apex/DMSPortalLwc.getProductCategories';
// import savePrimaryOrder from '@salesforce/apex/DMSPortalLwc.savePrimaryOrder';
// import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// export default class PrimaryOrder extends LightningElement {
//   @track allProducts = [];
//   @track quantities = {};
//   @track categories = [];
//   @track selectedCategory = '';
//   @track showSummary = false;
//   @track ShowAll =true;

//   // Load products
//   @wire(getActiveProducts)
//   wiredProducts({ data, error }) {
//     if (data) {
//       this.allProducts = data.map((p) => ({
//         ...p,
//         priceFormatted: this.formatCurrency(p.price)
//       }));
//     } else if (error) {
//       this.showToast('Failed to load products', 'error');
//     }
//   }

//   // Load categories from picklist
//   @wire(getProductCategories)
//   wiredCategories({ data, error }) {
//     if (data) {
//       this.categories = data;
//     } else if (error) {
//       this.showToast('Failed to load categories', 'error');
//     }
//   }

//  get filteredProducts() {
//     // Show all products if "All" is selected or nothing is selected
//     if (!this.selectedCategory || this.selectedCategory === 'All') {
//         return this.allProducts;
//     }
//     return this.allProducts.filter(p => p.category === this.selectedCategory);
// }

//  get summaryItems() {
//   return this.filteredProducts
//     .map(p => {
//       const quantity = this.quantities[p.id] || 0;
//       const price = p.price || 0;
//       const taxPercent = 18; // or from product data if available

//       const subtotal = quantity * price;
//       const taxAmount = parseFloat((subtotal * taxPercent / 100).toFixed(2));
//       const total = subtotal + taxAmount 

//       return {
//         id: p.id,
//         name: p.name,
//         quantity,
//         price,
//         priceFormatted: this.formatCurrency(price),
//         total,
//         totalFormatted: this.formatCurrency(total),
//         subtotal,
//         subtotalFormatted: this.formatCurrency(subtotal),
//         taxPercent,
//         taxAmount,
//         taxAmountFormatted: this.formatCurrency(taxAmount)
//       };
//     })
//     .filter(p => p.quantity > 0);
// }

//  get grandTotalFormatted() {
//   const total = this.summaryItems.reduce((sum, item) => sum + item.total, 0);
//   return this.formatCurrency(total);
// }
//   handleCategoryChange(event) {
//     this.selectedCategory = event.target.value;
//     this.quantities = {}; // reset quantities when category changes
//   }

//   handleQuantityChange(event) {
//     const productId = event.target.dataset.id;
//     const quantity = parseInt(event.target.value || '0', 10);
//     this.quantities[productId] = isNaN(quantity) ? 0 : quantity;
//   }

//   handleNext() {
//     if (this.summaryItems.length === 0) {
//       this.showToast('Please select at least one product.', 'error');
//       return;
//     }
//     this.ShowAll=false;
//     this.showSummary = true;
    
//   }

//   handleBack() {
//     this.showSummary = false;
//      this.ShowAll=true;
//   }

//  handleSave() {
//   const orderItems = [];
//   let grandTotal = 0;

//   for (let item of this.summaryItems) {
//     if (!item.id || !item.quantity || item.quantity <= 0) {
//       this.showToast('Validation Error', 'Please enter a valid quantity for all selected products.', 'error');
//       return;
//     }

//     // Add subtotal + tax amount to grand total
//     grandTotal += item.total + item.taxAmount;

//     orderItems.push({
//       sobjectType: 'Order_Item__c',
//       Product__c: item.id,
//       Quantity__c: item.quantity,
//       Total_Amount__c: item.total,
//       Tax_Percent__c: item.taxPercent,
//       Tax_Amount__c: item.taxAmount
//     });
//   }

//   if (orderItems.length === 0) {
//     this.showToast('No Products Selected', 'Please select at least one product before saving.', 'error');
//     return;
//   }

//   const order = {
//     sobjectType: 'Order__c',
//     Grand_Total__c: grandTotal,   // <-- Now includes tax amount
//     Order_Date__c: new Date().toISOString().split('T')[0]
//   };

//     savePrimaryOrder({ order: order, items: orderItems })
//     .then(() => {
//         this.showToast('Order created successfully.', 'success');
        
//         this.dispatchEvent(new CustomEvent('ordercreated', { bubbles: true, composed: true }));
//         this.resetForm();
//     })
//     .catch(error => {
//         console.error('Order Save Error:', error);
        
//     });
// }


//   formatCurrency(amount) {
//     return Number(amount || 0).toLocaleString('en-IN', {
//       style: 'decimal',
//       minimumFractionDigits: 2,
//       maximumFractionDigits: 2
//     });
//   }

//   showToast(message, variant) {
//     this.dispatchEvent(new ShowToastEvent({
//       title: variant === 'success' ? 'Success' : 'Error',
//       message,
//       variant
//     }));
//   }



//   handleCancel() {
//     this.dispatchEvent(new CustomEvent('cancel'));
// }

// }
















// import { LightningElement, track, wire } from 'lwc';
// import getActiveProducts from '@salesforce/apex/DMSPortalLwc.getActiveProducts';
// import getProductCategories from '@salesforce/apex/DMSPortalLwc.getProductCategories';
// import savePrimaryOrder from '@salesforce/apex/DMSPortalLwc.savePrimaryOrder';

// export default class PrimaryOrder extends LightningElement {
//   @track allProducts = [];
//   @track quantities = {};
//   @track categories = [];
//   @track selectedCategory = '';
//   @track showSummary = false;
//   @track ShowAll = true;

//   // Reference to the custom toast component
//   toastComponent;

//   // Load products
//   @wire(getActiveProducts)
//   wiredProducts({ data, error }) {
//     if (data) {
//       this.allProducts = data.map((p) => ({
//         ...p,
//         priceFormatted: this.formatCurrency(p.price)
//       }));
//     } else if (error) {
//       this.showToast('Failed to load products', 'error');
//     }
//   }

//   // Load categories from picklist
//   @wire(getProductCategories)
//   wiredCategories({ data, error }) {
//     if (data) {
//       this.categories = data;
//     } else if (error) {
//       this.showToast('Failed to load categories', 'error');
//     }
//   }

//   // Lifecycle hook to ensure the toast component is available after render
//   renderedCallback() {
//     if (!this.toastComponent) {
//       this.toastComponent = this.template.querySelector('c-custom-toast');
//     }
//   }

//   // Getter for filtered products based on selected category
//   get filteredProducts() {
//     // Show all products if "All" is selected or nothing is selected
//     if (!this.selectedCategory || this.selectedCategory === 'All') {
//         return this.allProducts;
//     }
//     return this.allProducts.filter(p => p.category === this.selectedCategory);
//   }

//   // Getter for summary items
//   get summaryItems() {
//     return this.filteredProducts
//       .map(p => {
//         const quantity = this.quantities[p.id] || 0;
//         const price = p.price || 0;
//         const taxPercent = 18; // or from product data if available

//         const subtotal = quantity * price;
//         const taxAmount = parseFloat((subtotal * taxPercent / 100).toFixed(2));
//         const total = subtotal + taxAmount;

//         return {
//           id: p.id,
//           name: p.name,
//           quantity,
//           price,
//           priceFormatted: this.formatCurrency(price),
//           total,
//           totalFormatted: this.formatCurrency(total),
//           subtotal,
//           subtotalFormatted: this.formatCurrency(subtotal),
//           taxPercent,
//           taxAmount,
//           taxAmountFormatted: this.formatCurrency(taxAmount)
//         };
//       })
//       .filter(p => p.quantity > 0);
//   }

//   // Grand total formatted with currency
//   get grandTotalFormatted() {
//     const total = this.summaryItems.reduce((sum, item) => sum + item.total, 0);
//     return this.formatCurrency(total);
//   }

//   // Handle category change and reset quantities
//   handleCategoryChange(event) {
//     this.selectedCategory = event.target.value;
//     this.quantities = {}; // Reset quantities when category changes
//   }

//   // Handle quantity change for each product
//   handleQuantityChange(event) {
//     const productId = event.target.dataset.id;
//     const quantity = parseInt(event.target.value || '0', 10);
//     this.quantities[productId] = isNaN(quantity) ? 0 : quantity;
//   }

//   // Handle Next action
//   handleNext() {
//     if (this.summaryItems.length === 0) {
//       this.showToast('Please select at least one product.', 'error');
//       return;
//     }
//     this.ShowAll = false;
//     this.showSummary = true;
//   }

//   // Handle Back action
//   handleBack() {
//     this.showSummary = false;
//     this.ShowAll = true;
//   }

//   // Handle Save action
//   handleSave() {
//     const orderItems = [];
//     let grandTotal = 0;

//     for (let item of this.summaryItems) {
//       if (!item.id || !item.quantity || item.quantity <= 0) {
//         this.showToast('Validation Error', 'Please enter a valid quantity for all selected products.', 'error');
//         return;
//       }

//       // Add subtotal + tax amount to grand total
//       grandTotal += item.total + item.taxAmount;

//       orderItems.push({
//         sobjectType: 'Order_Item__c',
//         Product__c: item.id,
//         Quantity__c: item.quantity,
//         Total_Amount__c: item.total,
//         Tax_Percent__c: item.taxPercent,
//         Tax_Amount__c: item.taxAmount
//       });
//     }

//     if (orderItems.length === 0) {
//       this.showToast('No Products Selected', 'error');
//       return;
//     }

//     const order = {
//       sobjectType: 'Order__c',
//       Grand_Total__c: grandTotal,   // Now includes tax amount
//       Order_Date__c: new Date().toISOString().split('T')[0]
//     };

//     savePrimaryOrder({ order: order, items: orderItems })
//       .then(() => {
//         this.showToast('Order created successfully.', 'success');
//         this.dispatchEvent(new CustomEvent('ordercreated', { bubbles: true, composed: true }));
//         this.resetForm();
//       })
//       .catch(error => {
//         console.error('Order Save Error:', error);
//         this.showToast('Failed to create order', 'error');
//       });
//   }

//   // Format currency with IN locale
//   formatCurrency(amount) {
//     return Number(amount || 0).toLocaleString('en-IN', {
//       style: 'decimal',
//       minimumFractionDigits: 2,
//       maximumFractionDigits: 2
//     });
//   }

//   // Show custom toast
//   showToast(message, variant) {
//     if (this.toastComponent) {
//       this.toastComponent.showToast(message, variant);
//     } else {
//       console.error('Toast component not found!');
//     }
//   }

//   // Handle Cancel action
//   handleCancel() {
//     this.dispatchEvent(new CustomEvent('cancel'));
//   }

//   // Reset form fields
//   resetForm() {
//     this.selectedCategory = '';
//     this.quantities = {};
//     this.showSummary = false;
//     this.ShowAll = true;
//   }
// }







import { LightningElement, track, wire } from 'lwc';
import getActiveProducts from '@salesforce/apex/DMSPortalLwc.getActiveProducts';
import getProductCategories from '@salesforce/apex/DMSPortalLwc.getProductCategories';
import savePrimaryOrder from '@salesforce/apex/DMSPortalLwc.savePrimaryOrder';

export default class PrimaryOrder extends LightningElement {
    @track allProducts = [];
    @track quantities = {};
    @track categories = [];
    @track selectedCategory = '';
    @track showSummary = false;
    @track ShowAll = true;

    // Load products
    @wire(getActiveProducts)
    wiredProducts({ data, error }) {
        if (data) {
            this.allProducts = data.map((p) => ({
                ...p,
                priceFormatted: this.formatCurrency(p.price)
            }));
        } else if (error) {
            this.showToast('Failed to load products', 'error');
        }
    }

    // Load categories from picklist
    @wire(getProductCategories)
    wiredCategories({ data, error }) {
        if (data) {
            this.categories = data;
        } else if (error) {
            this.showToast('Failed to load categories', 'error');
        }
    }

    // Getter for filtered products based on selected category
    get filteredProducts() {
        if (!this.selectedCategory || this.selectedCategory === 'All') {
            return this.allProducts;
        }
        return this.allProducts.filter(p => p.category === this.selectedCategory);
    }

    // Getter for summary items
    get summaryItems() {
        return this.filteredProducts
            .map(p => {
                const quantity = this.quantities[p.id] || 0;
                const price = p.price || 0;
                const taxPercent = 18; // or from product data if available

                const subtotal = quantity * price;
                const taxAmount = parseFloat((subtotal * taxPercent / 100).toFixed(2));
                const total = subtotal + taxAmount;

                return {
                    id: p.id,
                    name: p.name,
                    quantity,
                    price,
                    priceFormatted: this.formatCurrency(price),
                    total,
                    totalFormatted: this.formatCurrency(total),
                    subtotal,
                    subtotalFormatted: this.formatCurrency(subtotal),
                    taxPercent,
                    taxAmount,
                    taxAmountFormatted: this.formatCurrency(taxAmount)
                };
            })
            .filter(p => p.quantity > 0);
    }

    // Grand total formatted with currency
    get grandTotalFormatted() {
        const total = this.summaryItems.reduce((sum, item) => sum + item.total, 0);
        return this.formatCurrency(total);
    }

    // Handle category change and reset quantities
    handleCategoryChange(event) {
        this.selectedCategory = event.target.value;
        this.quantities = {}; // Reset quantities when category changes
        // this.showToast('Category changed successfully.', 'info'); // Toast to indicate category change
    }

    // Handle quantity change for each product
    handleQuantityChange(event) {
        const productId = event.target.dataset.id;
        const quantity = parseInt(event.target.value || '0', 10);
        this.quantities[productId] = isNaN(quantity) ? 0 : quantity;
    }

    // Handle Next action
    handleNext() {
        if (this.summaryItems.length === 0) {
            this.showToast('Please select at least one product.', 'error');
            return;
        }
        this.ShowAll = false;
        this.showSummary = true;
        
    }

    // Handle Back action
    handleBack() {
        this.showSummary = false;
        this.ShowAll = true;
        this.showToast('Going back to product selection.', 'info');
    }

    // Handle Save action
handleSave() {
    const orderItems = [];
    let grandTotal = 0;



    for (let item of this.summaryItems) {
       

        // Add subtotal + tax amount to grand total
        grandTotal += item.total + item.taxAmount;

        orderItems.push({
            sobjectType: 'Order_Item__c',
            Product__c: item.id,
            Quantity__c: item.quantity,
            Total_Amount__c: item.total,
            Tax_Percent__c: item.taxPercent,
            Tax_Amount__c: item.taxAmount
        });
    }

   
    const order = {
        sobjectType: 'Order__c',
        Grand_Total__c: grandTotal,   // Now includes tax amount
        Order_Date__c: new Date().toISOString().split('T')[0]
    };

    // Calling savePrimaryOrder
   savePrimaryOrder({ order, items: orderItems })
        .then((result) => {
            console.log('Order saved:', result);
            this.showToast('Order created successfully.', 'success');
            setTimeout(() => {
                this.dispatchEvent(new CustomEvent('ordercreated'));
                this.resetForm();
            }, 1000);
        })
        .catch((error) => {
            console.error('Error:', error);
            this.showToast('Failed to create order', 'error');
        });
      }



      
// Show custom toast using the customToast component
showToast(message, variant) {
    const toast = this.template.querySelector('c-custom-toast'); // Query the toast component
    console.log('Custom Toast component:', toast);  // Log the reference

    if (toast) {
        toast.showToast(variant, message); // Show the toast
    } else {
        console.error('Custom Toast component not found!');
    }
}

    // Format currency with IN locale
    formatCurrency(amount) {
        return Number(amount || 0).toLocaleString('en-IN', {
            style: 'decimal',
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        });
    }

    // Show custom toast
    showToast(message, variant) {
        const toast = this.template.querySelector('c-custom-toast'); // Query the toast component
        if (toast) {
            toast.showToast(variant, message); // Show the toast
        } else {
            console.error('Custom Toast component not found!');
        }
    }

    // Handle Cancel action
    handleCancel() {
        this.dispatchEvent(new CustomEvent('cancel'));
    }

    // Reset form fields
    resetForm() {
        this.selectedCategory = '';
        this.quantities = {};
        this.showSummary = false;
        this.ShowAll = true;
    }
}