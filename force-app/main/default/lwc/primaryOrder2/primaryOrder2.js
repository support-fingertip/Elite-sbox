// import { LightningElement, track } from 'lwc';
// import getActiveProducts from '@salesforce/apex/ProductControllerGRIDVIEW.getActiveProducts';
// import getSizePicklistValues from '@salesforce/apex/ProductControllerGRIDVIEW.getSizePicklistValues';
// import getProductCategories from '@salesforce/apex/ProductControllerGRIDVIEW.getProductCategories';
// import savePrimaryOrder from '@salesforce/apex/DMSPortalLwc.savePrimaryOrder';
// import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// export default class PrimaryOrderGrid extends LightningElement {
//   @track allProducts = [];
//   @track filteredProducts = [];
//   @track sizes = [];
//   @track categories = [];
//   @track selectedCategory = 'All';
//   @track showSummary = false;
//   @track summaryItems = [];
//   @track grandTotal = 0;
//   @track grandTotalFormatted = '0';

//   connectedCallback() {
//     this.loadInitialData();
//   }
//   // Add to primaryOrder2.js

// // In primaryOrder2.js - add to your class
// renderedCallback() {
//     // Add stability to input elements
//     this.template.querySelectorAll('.custom-quantity-input').forEach(input => {
//         input.addEventListener('blur', this.handleInputBlur.bind(this));
//     });
// }

// disconnectedCallback() {
//     // Clean up event listeners
//     this.template.querySelectorAll('.custom-quantity-input').forEach(input => {
//         input.removeEventListener('blur', this.handleInputBlur.bind(this));
//     });
// }

//   loadInitialData() {
//     Promise.all([
//       getSizePicklistValues(),
//       getProductCategories(),
//       getActiveProducts()
//     ])
//       .then(([sizeValues, categoryValues, products]) => {
//         this.sizes = sizeValues;
//         this.categories = ['All', ...categoryValues];
//         this.selectedCategory = 'All';

//        this.allProducts = products.map((prod, index) => {
//   const quantityMap = {};
//   const sizesData = this.sizes.map(size => {
//     quantityMap[size] = 0;
//     const sizeInfo = prod.sizes ? prod.sizes[size] : null;
//     console.log('sizeinfo'+ JSON.stringify(sizeInfo))
//     return {
//       size,
//       quantity: 0,
//       priceFormatted: sizeInfo && sizeInfo.price ? sizeInfo.price.toFixed(0) : '0',
//       price: sizeInfo && sizeInfo.price ? sizeInfo.price : 0,
//       productId: sizeInfo && sizeInfo.productId ? sizeInfo.productId : null
//     };
//   });

//   return {
//     ...prod,
//     id: prod.Id || prod.id || prod.productId || `prod-${index}`, // 🔥 Ensures unique ID
//     quantityMap,
//     sizesData
//   };
// });

//         this.applyFilters();
//       })
//       .catch(error => {
//         this.showToast('Error loading initial data', 'error');
//         console.error(error);
//       });
//   }

//   get categoryOptions() {
//     return this.categories.map(cat => ({ label: cat, value: cat }));
//   }

//   applyFilters() {
//     if (this.selectedCategory === 'All') {
//       this.filteredProducts = [...this.allProducts];
//     } else {
//       this.filteredProducts = this.allProducts.filter(p => p.category === this.selectedCategory);
//     }
//   }

//   handleCategoryChange(event) {
//     this.selectedCategory = event.detail.value;
//     this.applyFilters();
//   }
// handleQuantityChange(event) {
//     const productId = event.target.dataset.id;
//     const size = event.target.dataset.size;
//     const value = parseInt(event.target.value || 0, 10);

//   const productIndex = this.filteredProducts.findIndex(p => p.id === productId);
//   if (productIndex === -1) return;

//   const product = { ...this.filteredProducts[productIndex] };

//   if (!product.quantityMap) {
//     product.quantityMap = {};
//   }
//   product.quantityMap[size] = isNaN(value) ? 0 : value;

//   if (product.sizesData) {
//     const sizeDataIndex = product.sizesData.findIndex(s => s.size === size);
//     if (sizeDataIndex !== -1) {
//       product.sizesData = [...product.sizesData]; // clone for reactivity
//       product.sizesData[sizeDataIndex] = {
//         ...product.sizesData[sizeDataIndex],
//         quantity: isNaN(value) ? 0 : value
//       };
//     }
//   }

//   // Ensure filteredProducts is updated immutably
//   this.filteredProducts = [
//     ...this.filteredProducts.slice(0, productIndex),
//     product,
//     ...this.filteredProducts.slice(productIndex + 1)
//   ];
// }


// handleInputBlur(event) {
//     // Prevent default blur behavior that causes issues
//     event.preventDefault();
//     event.stopPropagation();
//     // Immediately refocus if needed (optional)
//     // event.target.focus();
// }
//  // Update in primaryOrder2.js
// handleReview() {
//     this.summaryItems = [];
//     this.grandTotal = 0;
//     let hasItems = false;

//     this.filteredProducts.forEach(product => {
//         if (!product.quantityMap) return;
        
//         this.sizes.forEach(size => {
//             const qty = product.quantityMap[size] || 0;
//             if (qty > 0) {
//                 hasItems = true;
//                 const sizeInfo = product.sizes ? product.sizes[size] : null;
//                 const price = sizeInfo ? sizeInfo.price : 0;
//                 const taxAmount = (18 * price * qty) / 100;
//                 const subtotal = (qty * price) + taxAmount;

//                 this.summaryItems.push({
//                     key: `${product.id}-${size}`,
//                     product: product.name,
//                     size,
//                     quantity: qty,
//                     rate: price,
//                     rateFormatted: price.toFixed(2) || 0,
//                     subtotal,
//                     subtotalFormatted: subtotal.toFixed(2) || 0,
//                     productId: sizeInfo ? sizeInfo.productId : null,
//                     category: product.category || null,
//                     taxPercent: 18,
//                     taxAmount: parseFloat(((qty * price * 18) / 100).toFixed(2)) || 0
//                 });

//                 this.grandTotal += subtotal;
//             }
//         });
//     });

//     if (!hasItems) {
//         this.dispatchEvent(
//             new ShowToastEvent({
//                 title: 'Error',
//                 message: 'Please enter quantity for at least one product size.',
//                 variant: 'error',
//                 mode: 'sticky' // Make sure it stays visible
//             })
//         );
//         return;
//     }

//     this.grandTotalFormatted = this.grandTotal.toFixed(2);
//     this.showSummary = true;
// }

//   handleBack() {
//     this.showSummary = false;
//   }

//   handleSave() {
//     const orderItems = this.summaryItems.map(item => ({
//       sobjectType: 'Order_Item__c',
//       Product__c: item.productId,
//       Quantity__c: item.quantity,
//       Size__c: item.size,
//         Tax_Percent__c: item.taxPercent,
//   Tax_Amount__c: item.taxAmount

//     }));
//     console.log(JSON.stringify(this.summaryItems))
//      console.log('Product IDs being sent:', orderItems.map(i => i.Product__c));
//     const grandTotal = this.summaryItems.reduce((acc, item) => acc + item.subtotal, 0);

//     const order = {
//       sobjectType: 'Order__c',
//       Order_Date__c: new Date().toISOString().split('T')[0], // 'YYYY-MM-DD'
    
//     };

//     savePrimaryOrder({ order, items: orderItems })
//       .then(() => {
//         this.showToast('Order saved successfully!', 'success');
//         this.dispatchEvent(new CustomEvent('ordercreated', { bubbles: true, composed: true }));
//         this.resetForm();
//       })
//       .catch(error => {
//         this.showToast('Error saving order.', 'error');
//         console.error(error);
//       });
//   }

//   showToast(message, variant) {
//     this.dispatchEvent(
//       new ShowToastEvent({
//         title: variant === 'error' ? 'Error' : 'Success',
//         message,
//         variant
//       })
//     );
//   }
// }



// import { LightningElement, track } from 'lwc';
// import getActiveProducts from '@salesforce/apex/ProductControllerGRIDVIEW.getActiveProducts';
// import getSizePicklistValues from '@salesforce/apex/ProductControllerGRIDVIEW.getSizePicklistValues';
// import getProductCategories from '@salesforce/apex/ProductControllerGRIDVIEW.getProductCategories';
// import savePrimaryOrder from '@salesforce/apex/DMSPortalLwc.savePrimaryOrder';


// export default class PrimaryOrderGrid extends LightningElement {
//   @track allProducts = [];
//   @track filteredProducts = [];
//   @track sizes = [];
//   @track categories = [];
//   @track selectedCategory = 'All';
//   @track showSummary = false;
//   @track summaryItems = [];
//   @track grandTotal = 0;
//   @track grandTotalFormatted = '0';

//   connectedCallback() {
//     this.loadInitialData();
//   }
//   // Add to primaryOrder2.js

// // In primaryOrder2.js - add to your class
// renderedCallback() {
//     // Add stability to input elements
//     this.template.querySelectorAll('.custom-quantity-input').forEach(input => {
//         input.addEventListener('blur', this.handleInputBlur.bind(this));
//     });
// }

// disconnectedCallback() {
//     // Clean up event listeners
//     this.template.querySelectorAll('.custom-quantity-input').forEach(input => {
//         input.removeEventListener('blur', this.handleInputBlur.bind(this));
//     });
// }

//   loadInitialData() {
//     Promise.all([
//       getSizePicklistValues(),
//       getProductCategories(),
//       getActiveProducts()
//     ])
//       .then(([sizeValues, categoryValues, products]) => {
//         this.sizes = sizeValues;
//         this.categories = ['All', ...categoryValues];
//         this.selectedCategory = 'All';

//        this.allProducts = products.map((prod, index) => {
//   const quantityMap = {};
//   const sizesData = this.sizes.map(size => {
//     quantityMap[size] = 0;
//     const sizeInfo = prod.sizes ? prod.sizes[size] : null;
//     console.log('sizeinfo'+ JSON.stringify(sizeInfo))
//     return {
//       size,
//       quantity: 0,
//       priceFormatted: sizeInfo && sizeInfo.price ? sizeInfo.price.toFixed(0) : '0',
//       price: sizeInfo && sizeInfo.price ? sizeInfo.price : 0,
//       productId: sizeInfo && sizeInfo.productId ? sizeInfo.productId : null
//     };
//   });

//   return {
//     ...prod,
//     id: prod.Id || prod.id || prod.productId || `prod-${index}`, // 🔥 Ensures unique ID
//     quantityMap,
//     sizesData
//   };
// });

//         this.applyFilters();
//       })
//       .catch(error => {
//         this.showToast('Error loading initial data', 'error');
//         console.error(error);
//       });
//   }

//   get categoryOptions() {
//     return this.categories.map(cat => ({ label: cat, value: cat }));
//   }

//   applyFilters() {
//     if (this.selectedCategory === 'All') {
//       this.filteredProducts = [...this.allProducts];
//     } else {
//       this.filteredProducts = this.allProducts.filter(p => p.category === this.selectedCategory);
//     }
//   }

//   handleCategoryChange(event) {
//     this.selectedCategory = event.detail.value;
//     this.applyFilters();
//   }
// handleQuantityChange(event) {
//     const productId = event.target.dataset.id;
//     const size = event.target.dataset.size;
//     const value = parseInt(event.target.value || 0, 10);

//   const productIndex = this.filteredProducts.findIndex(p => p.id === productId);
//   if (productIndex === -1) return;

//   const product = { ...this.filteredProducts[productIndex] };

//   if (!product.quantityMap) {
//     product.quantityMap = {};
//   }
//   product.quantityMap[size] = isNaN(value) ? 0 : value;

//   if (product.sizesData) {
//     const sizeDataIndex = product.sizesData.findIndex(s => s.size === size);
//     if (sizeDataIndex !== -1) {
//       product.sizesData = [...product.sizesData]; // clone for reactivity
//       product.sizesData[sizeDataIndex] = {
//         ...product.sizesData[sizeDataIndex],
//         quantity: isNaN(value) ? 0 : value
//       };
//     }
//   }

//   // Ensure filteredProducts is updated immutably
//   this.filteredProducts = [
//     ...this.filteredProducts.slice(0, productIndex),
//     product,
//     ...this.filteredProducts.slice(productIndex + 1)
//   ];
// }


// handleInputBlur(event) {
//     // Prevent default blur behavior that causes issues
//     event.preventDefault();
//     event.stopPropagation();
//     // Immediately refocus if needed (optional)
//     // event.target.focus();
// }
//  // Update in primaryOrder2.js
// handleReview() {
//     this.summaryItems = [];
//     this.grandTotal = 0;
//     let hasItems = false;

//     this.filteredProducts.forEach(product => {
//         if (!product.quantityMap) return;
        
//         this.sizes.forEach(size => {
//             const qty = product.quantityMap[size] || 0;
//             if (qty > 0) {
//                 hasItems = true;
//                 const sizeInfo = product.sizes ? product.sizes[size] : null;
//                 const price = sizeInfo ? sizeInfo.price : 0;
//                 const taxAmount = (18 * price * qty) / 100;
//                 const subtotal = (qty * price) + taxAmount;

//                 this.summaryItems.push({
//                     key: `${product.id}-${size}`,
//                     product: product.name,
//                     size,
//                     quantity: qty,
//                     rate: price,
//                     rateFormatted: price.toFixed(2) || 0,
//                     subtotal,
//                     subtotalFormatted: subtotal.toFixed(2) || 0,
//                     productId: sizeInfo ? sizeInfo.productId : null,
//                     category: product.category || null,
//                     taxPercent: 18,
//                     taxAmount: parseFloat(((qty * price * 18) / 100).toFixed(2)) || 0
//                 });

//                 this.grandTotal += subtotal;
//             }
//         });
//     });

//     if (!hasItems) {
//         this.dispatchEvent(
//             new ShowToastEvent({
//                 title: 'Error',
//                 message: 'Please enter quantity for at least one product size.',
//                 variant: 'error',
//                 mode: 'sticky' // Make sure it stays visible
//             })
//         );
//         return;
//     }

//     this.grandTotalFormatted = this.grandTotal.toFixed(2);
//     this.showSummary = true;
// }

//   handleBack() {
//     this.showSummary = false;
//   }

//   handleSave() {
//     const orderItems = this.summaryItems.map(item => ({
//       sobjectType: 'Order_Item__c',
//       Product__c: item.productId,
//       Quantity__c: item.quantity,
//       Size__c: item.size,
//         Tax_Percent__c: item.taxPercent,
//   Tax_Amount__c: item.taxAmount

//     }));
//     console.log(JSON.stringify(this.summaryItems))
//      console.log('Product IDs being sent:', orderItems.map(i => i.Product__c));
//     const grandTotal = this.summaryItems.reduce((acc, item) => acc + item.subtotal, 0);

//     const order = {
//       sobjectType: 'Order__c',
//       Order_Date__c: new Date().toISOString().split('T')[0], // 'YYYY-MM-DD'
    
//     };

//     savePrimaryOrder({ order, items: orderItems })
//       .then(() => {
//         this.showToast('Order saved successfully!', 'success');
//         setTimeout(() => {
//                 this.dispatchEvent(new CustomEvent('ordercreated'));
//                 this.resetForm();
//             }, 1000);
//       })
//       .catch(error => {
//         this.showToast('Error saving order.', 'error');
//         console.error(error);
//       });
//   }

//  showToast(message, variant) {
//     const toast = this.template.querySelector('c-custom-toast'); // Query the toast component
//     console.log('Custom Toast component:', toast);  // Log the reference

//     if (toast) {
//         toast.showToast(variant, message); // Show the toast
//     } else {
//         console.error('Custom Toast component not found!');
//     }
// }
// }




import { LightningElement, track } from 'lwc';
import getActiveProducts from '@salesforce/apex/ProductControllerGRIDVIEW.getActiveProducts';
import getSizePicklistValues from '@salesforce/apex/ProductControllerGRIDVIEW.getSizePicklistValues';
import getProductCategories from '@salesforce/apex/ProductControllerGRIDVIEW.getProductCategories';
import savePrimaryOrder from '@salesforce/apex/DMSPortalLwc.savePrimaryOrder';

export default class PrimaryOrderGrid extends LightningElement {
  @track allProducts = [];
  @track filteredProducts = [];
  @track sizes = [];
  @track categories = [];
  @track selectedCategory = 'All';
  @track showSummary = false;
  @track summaryItems = [];
  @track grandTotal = 0;
  @track grandTotalFormatted = '0';

  connectedCallback() {
    this.loadInitialData();
  }

  // Add to primaryOrder2.js
  renderedCallback() {
    // Add stability to input elements
    this.template.querySelectorAll('.custom-quantity-input').forEach(input => {
        input.addEventListener('blur', this.handleInputBlur.bind(this));
    });
  }

  disconnectedCallback() {
    // Clean up event listeners
    this.template.querySelectorAll('.custom-quantity-input').forEach(input => {
        input.removeEventListener('blur', this.handleInputBlur.bind(this));
    });
  }

  loadInitialData() {
    Promise.all([
      getSizePicklistValues(),
      getProductCategories(),
      getActiveProducts()
    ])
      .then(([sizeValues, categoryValues, products]) => {
        this.sizes = sizeValues;
        this.categories = ['All', ...categoryValues];
        this.selectedCategory = 'All';

        this.allProducts = products.map((prod, index) => {
          const quantityMap = {};
          const sizesData = this.sizes.map(size => {
            quantityMap[size] = 0;
            const sizeInfo = prod.sizes ? prod.sizes[size] : null;
            console.log('sizeinfo' + JSON.stringify(sizeInfo))
            return {
              size,
              quantity: 0,
              priceFormatted: sizeInfo && sizeInfo.price ? sizeInfo.price.toFixed(0) : '0',
              price: sizeInfo && sizeInfo.price ? sizeInfo.price : 0,
              productId: sizeInfo && sizeInfo.productId ? sizeInfo.productId : null
            };
          });

          return {
            ...prod,
            id: prod.Id || prod.id || prod.productId || `prod-${index}`, // 🔥 Ensures unique ID
            quantityMap,
            sizesData
          };
        });

        this.applyFilters();
      })
      .catch(error => {
        this.showToast('Error loading initial data', 'error');
        console.error(error);
      });
  }

  get categoryOptions() {
    return this.categories.map(cat => ({ label: cat, value: cat }));
  }

  applyFilters() {
    if (this.selectedCategory === 'All') {
      this.filteredProducts = [...this.allProducts];
    } else {
      this.filteredProducts = this.allProducts.filter(p => p.category === this.selectedCategory);
    }
  }

  handleCategoryChange(event) {
    this.selectedCategory = event.detail.value;
    this.applyFilters();
  }

  handleQuantityChange(event) {
    const productId = event.target.dataset.id;
    const size = event.target.dataset.size;
    const value = parseInt(event.target.value || 0, 10);

    const productIndex = this.filteredProducts.findIndex(p => p.id === productId);
    if (productIndex === -1) return;

    const product = { ...this.filteredProducts[productIndex] };

    if (!product.quantityMap) {
      product.quantityMap = {};
    }
    product.quantityMap[size] = isNaN(value) ? 0 : value;

    if (product.sizesData) {
      const sizeDataIndex = product.sizesData.findIndex(s => s.size === size);
      if (sizeDataIndex !== -1) {
        product.sizesData = [...product.sizesData]; // clone for reactivity
        product.sizesData[sizeDataIndex] = {
          ...product.sizesData[sizeDataIndex],
          quantity: isNaN(value) ? 0 : value
        };
      }
    }

    // Ensure filteredProducts is updated immutably
    this.filteredProducts = [
      ...this.filteredProducts.slice(0, productIndex),
      product,
      ...this.filteredProducts.slice(productIndex + 1)
    ];
  }

  handleInputBlur(event) {
    // Prevent default blur behavior that causes issues
    event.preventDefault();
    event.stopPropagation();
    // Immediately refocus if needed (optional)
    // event.target.focus();
  }

  handleReview() {
    this.summaryItems = [];
    this.grandTotal = 0;
    let hasItems = false;

    this.filteredProducts.forEach(product => {
      if (!product.quantityMap) return;
      
      this.sizes.forEach(size => {
        const qty = product.quantityMap[size] || 0;
        if (qty > 0) {
          hasItems = true;
          const sizeInfo = product.sizes ? product.sizes[size] : null;
          const price = sizeInfo ? sizeInfo.price : 0;
          const taxAmount = (18 * price * qty) / 100;
          const subtotal = (qty * price) + taxAmount;

          this.summaryItems.push({
            key: `${product.id}-${size}`,
            product: product.name,
            size,
            quantity: qty,
            rate: price,
            rateFormatted: price.toFixed(2) || 0,
            subtotal,
            subtotalFormatted: subtotal.toFixed(2) || 0,
            productId: sizeInfo ? sizeInfo.productId : null,
            category: product.category || null,
            taxPercent: 18,
            taxAmount: parseFloat(((qty * price * 18) / 100).toFixed(2)) || 0
          });

          this.grandTotal += subtotal;
        }
      });
    });

    if (!hasItems) {
      this.showToast('Error','Please select atleast one product and some quantity', 'error');
      return;
    }

    this.grandTotalFormatted = this.grandTotal.toFixed(2);
    this.showSummary = true;
  }

  handleBack() {
    this.showSummary = false;
  }

  handleSave() {
    const orderItems = this.summaryItems.map(item => ({
      sobjectType: 'Order_Item__c',
      Product__c: item.productId,
      Quantity__c: item.quantity,
      Size__c: item.size,
      Tax_Percent__c: item.taxPercent,
      Tax_Amount__c: item.taxAmount
    }));

    console.log(JSON.stringify(this.summaryItems));
    console.log('Product IDs being sent:', orderItems.map(i => i.Product__c));

    const grandTotal = this.summaryItems.reduce((acc, item) => acc + item.subtotal, 0);

    const order = {
      sobjectType: 'Order__c',
      Order_Date__c: new Date().toISOString().split('T')[0], // 'YYYY-MM-DD'
    };

    savePrimaryOrder({ order, items: orderItems })
      .then(() => {
        this.showToast('success','Order saved successfully!', 'success');
        setTimeout(() => {
          this.dispatchEvent(new CustomEvent('ordercreated'));
          this.resetForm();
        }, 1000);
      })
      .catch(error => {
        this.showToast('Error saving order.', 'error');
        console.error(error);
      });
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
    
}