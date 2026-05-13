# Price & Price Book Fetching Logic — Order Screen

**Component:** `productScreen4` (LWC)
**Files covered:**
- `force-app/main/default/lwc/productScreen4/productScreen4.html`
- `force-app/main/default/lwc/productScreen4/productScreen4.js`
- `force-app/main/default/classes/beatPlannerlwc.cls`

This document explains, end-to-end, how unit prices are fetched, calculated, and
displayed on the Order screen for both **Primary Orders** (Distributor / Direct
B2B) and **Secondary Orders** (Retailer / Distribution).

---

## 1. High-Level Overview

```
                ┌─────────────────────────────────────────────┐
                │  productScreen4 (LWC) — Order Screen        │
                └─────────────────────────────────────────────┘
                                  │
                                  ▼ wire / imperative call
                ┌─────────────────────────────────────────────┐
                │  beatPlannerlwc.getSchemeWiseOrderData      │
                │  (visitId, AccountId, orderRecordId)        │
                └─────────────────────────────────────────────┘
                                  │
       ┌──────────────────────────┴───────────────────────────┐
       ▼                                                      ▼
  PRIMARY CUSTOMER                                  SECONDARY CUSTOMER
  ─────────────────                                  ────────────────────
  1. Last Invoice price (≤ 30 days)                 1. Price Book (Account-specific)
  2. Price Book (Customer=Account, Primary)         2. Price Book (Secondary Category)
  3. Product List Price                             3. Price Book (Sales Channel)
                                                    4. Apply Price_Change discount
                                                    5. Auto-select best Scheme
                                  │
                                  ▼
                ┌─────────────────────────────────────────────┐
                │ productData[] / schemePro[] / schemeOffer[] │
                └─────────────────────────────────────────────┘
                                  │
                                  ▼
                        Render in productScreen4.html
                        (Cards + Order Summary table)
                                  │
                                  ▼
                ┌─────────────────────────────────────────────┐
                │   beatPlannerlwc.upsertOrder()              │
                │   Persists full price trail on Order_Item__c│
                └─────────────────────────────────────────────┘
```

The same Apex entry point (`getSchemeWiseOrderData`) serves both flows; branching
happens **inside** the method based on the Account's `Customer_Type__c`.

---

## 2. Apex Layer — `beatPlannerlwc.cls`

### 2.1 Entry point: `getSchemeWiseOrderData` (line 1481)

**Signature**
```apex
@AuraEnabled
public static Map<String,Object> getSchemeWiseOrderData(
    Id visitId,
    Id AccountId,
    Id orderRecordId        // null for new order, populated for edit mode
)
```

**Returns** (Map keys consumed by JS):
| Key | Purpose |
|-----|---------|
| `strategyProductMapList` | Products grouped by Sales Strategy |
| `allProDtas` | Flat list of all products with pricing |
| `schemessss` | Available schemes (secondary only) |
| `minumumOrderValue` | Minimum order threshold from running user |
| `existingOrderProductQuantities` | Quantity map for edit mode |

### 2.2 Price-source queries

**Primary Customer branch** (`beatPlannerlwc.cls:1597–1604`):
```apex
// Product with customer-specific Price Book + last-30-day Invoice price
SELECT Id, Name, List_Price__c, MRP__c, Tax__c, ...
       (SELECT Unit_Price__c, MRP__c, Delivery_Plant__c
          FROM Price_Books__r
         WHERE Customer_Type__c = 'Primary Customer'
           AND Customer__c = :AccountId),
       (SELECT Price_per_unit__c
          FROM Invoice_items__r
         WHERE CreatedDate = LAST_N_DAYS:30
         ORDER BY CreatedDate DESC LIMIT 1)
  FROM Product2 WHERE ...
```

**Secondary Customer branch** (`beatPlannerlwc.cls:1607–1614`):
```apex
SELECT Id, Name, List_Price__c, MRP__c, Tax__c,
       (SELECT Unit_Price__c, MRP__c, Sales_Channel__c,
               Secondary_Customer_Category__c, Customer__c
          FROM Price_Books__r
         WHERE Customer_Type__c = 'Secondary Customer'
           AND (Customer__c = :AccountId
                OR Secondary_Customer_Category__c = :acc.Category__c
                OR Sales_Channel__c = :acc.Sales_Channel__c))
  FROM Product2 WHERE ...
```

### 2.3 Price-resolution hierarchy (`beatPlannerlwc.cls:1620–1705`)

**Primary Customer — first match wins:**
1. `p.Invoice_items__r[0].Price_per_unit__c` (last invoice within 30 days) — *line 1652*
2. `p.Price_Books__r[0].Unit_Price__c` (Primary price book row) — *line 1657*
3. `p.List_Price__c` (Product master fallback) — *line 1681*
4. `MRP` = `p.Price_Books__r[0].MRP__c` if present else `p.MRP__c`
5. `deliveryPlant` = `p.Price_Books__r[0].Delivery_Plant__c` (Primary only)

**Secondary Customer — first match wins:**
1. Price Book where `Customer__c = AccountId` — *line 1630–1632*
2. Price Book where `Secondary_Customer_Category__c = acc.Category__c` — *line 1633–1635*
3. Price Book where `Sales_Channel__c = acc.Sales_Channel__c` — *line 1636–1638*

Then a **Price_Change__c override** is applied (lines 1553–1562, 1660–1676):
```apex
// Price_Change__c has: Customer_Category__c, Off__c (%), Type__c
if (pc.Type__c == 'MRP')          basePrice = MRP;
else /* Unit Price */              basePrice = unitPrice;
finalPrice = basePrice * (1 - pc.Off__c / 100);
```

### 2.4 DTO returned to LWC (`beatPlannerlwc.cls:4213–4248` — `productData`)

| Field | Meaning |
|-------|---------|
| `UnitPricePriceBook` | Final unit price *after* Price_Change but *before* schemes |
| `MRP` | Maximum Retail Price |
| `originalUnitPrice` | Pre-scheme price (snapshot) |
| `discountedPrice` | Total scheme savings (filled by JS) |
| `discountedUnitPrice` | Per-unit price after scheme (filled by JS) |
| `taxPercent` | GST/Tax % from `Product2.Tax__c` |
| `deliveryPlant` | Only populated for Primary |

### 2.5 Persistence: `upsertOrder` (`beatPlannerlwc.cls:2238`)

The method writes a **full audit trail** of price transformations onto
`Order_Item__c`:

| Order_Item__c field | Source (line) | Meaning |
|---------------------|---------------|---------|
| `Unit_price__c` | 2553–2563 | Final billed unit price |
| `Before_Category_Slab_Unit_Price__c` | 2566–2573 | Before Price_Change |
| `After_Category_Slab_Unit_Price__c` | 2575–2582 | After Price_Change |
| `Before_Scheme_Unit_Price__c` | 2585–2592 | Before scheme |
| `After_Scheme_Unit_Price__c` | 2594–2601 | After scheme |
| `Scheme_Item__c` | 2603–2606 | FK to `Buy_Product__c` of applied scheme |
| `Tax__c` | 2608 | GST % |
| `Tax_Amount__c` | 2609 | qty × price × tax% |
| `Total_Amount__c` | 2610 | Net (price × qty + tax) |

For Primary orders, `Before_Scheme_*` = `After_Scheme_*` (no schemes apply) and
`Scheme_Item__c` is null.

---

## 3. LWC Controller — `productScreen4.js`

### 3.1 Initial data load — `getData()` (line 257)

```js
getSchemeWiseOrderData({ visitId, AccountId, orderRecordId })
  .then(response => {
      this.schemePro      = response.strategyProductMapList;
      this.productData    = response.allProDtas;
      this.schemeOffer    = response.schemessss;       // secondary only
      this.allProDtas     = response.allProDtas;
      // Edit mode — re-hydrate quantities (lines 321–353)
      // Mark scheme availability per product (lines 355–369)
  });
```

For each product, the JS flags:
```js
product.hasApplicableSchemes = this.schemeOffer.some(scheme =>
    scheme.lineItems.some(item => item.productId === product.id)
);
product.applicableSchemes = this.schemeOffer
    .flatMap(s => s.lineItems)
    .filter(item => item.productId === product.id);
```

This drives the scheme ribbon icon in HTML for secondary customers.

### 3.2 Quantity handlers — the Primary vs Secondary fork

**Primary — dual input (Cases + Each):**
- `handleCrateQtyChange` (`productScreen4.js:1454`)
- `handleEachQtyChange` (`productScreen4.js:1477`)

```js
totalQty = (crateQty * uomConversion) + eachQty;
item.totalQty   = totalQty;
item.totalPrice = item.UnitPricePriceBook * totalQty;   // no scheme
this.recalculateTotals();
```

**Secondary — single input (Each only):**
- `handleEachQtyChange` (same method, `productScreen4.js:1477`)
- After quantity update, lines 1500–1502:
```js
this.syncQuantityToSchemeOffer(productId, newQty, totalValue);
this.autoSelectBestScheme(productId);
this.recalculateTotals();
```

### 3.3 Scheme auto-selection — `autoSelectBestScheme` (line 1578)

```js
autoSelectBestScheme(productId) {
    let maxSavings = { discountAmount: 0 };
    let bestScheme = null;
    for (const scheme of applicableSchemes) {
        const savings = this.calculateSchemeBenefit(product, scheme);
        if (savings.discountAmount >= maxSavings.discountAmount) {
            maxSavings = savings;
            bestScheme = scheme;
        }
    }
    product.discountedPrice      = maxSavings.discountAmount;
    product.discountedUnitPrice  = maxSavings.finalUnitPrice;
    product.appliedScheme        = !!bestScheme;
    product.schemeItemId         = bestScheme?.id;
}
```

### 3.4 Scheme math — `calculateSchemeBenefit` (line 1683)

Three scheme types are supported:

**a) Free Product (lines 1705–1734)**
```
if (qty >= minQty)
   freeUnits      = floor(qty / minQty) * freeQty
   effectiveQty   = qty + freeUnits
   finalUnitPrice = (unitPrice * qty) / effectiveQty
   discountAmount = (unitPrice - finalUnitPrice) * effectiveQty
```

**b) Per-UOM Discount (lines 1738–1753)**
```
if (qty >= saleValueThreshold)
   finalUnitPrice = unitPrice - discountPerUnit
   discountAmount = discountPerUnit * qty
```

**c) Sale Value Discount (lines 1756–1774)**
```
baseTotal = unitPrice * qty
if (baseTotal >= saleValueThreshold)
   discountedTotal = baseTotal * (1 - discountPercent / 100)
   discountAmount  = baseTotal - discountedTotal
   finalUnitPrice  = discountedTotal / qty
```

### 3.5 Totals — `recalculateTotals` (line 1784)

```js
for (const item of [...schemePro, ...productData]) {
    const unitPrice = item.appliedScheme
        ? item.discountedUnitPrice          // secondary, scheme applied
        : item.UnitPricePriceBook;          // primary or no scheme
    const lineTotal = unitPrice * item.totalQty;
    const taxAmt    = lineTotal * (item.taxPercent / 100);
    this.subTotalAmt   += lineTotal;
    this.totalTaxAmt   += taxAmt;
    this.grandTotalAmt += lineTotal + taxAmt;
}
```

### 3.6 Summary builder — `setProducts` (line 2032)

**Primary path (1934–2019)** — groups by `deliveryPlant`:
```js
plantGroups[plant] = {
    plantName: 'Delivery Plant: ' + plant,
    products:  [{ displayQty, caseQuantity, unitPrice: UnitPricePriceBook,
                  taxPercent, taxAmt, netValue }],
    plantSubTotal, plantTax, plantTotal
};
```

**Secondary path (2052–2107)** — single "All Products" group, uses
`discountedUnitPrice` when a scheme is applied:
```js
const unitPrice = item.appliedScheme
    ? item.discountedUnitPrice
    : item.UnitPricePriceBook;
const taxAmt    = unitPrice * qty * taxPercent / 100;
const netTotal  = unitPrice * qty + taxAmt;
totalDiscount  += item.discountedPrice || 0;
```

---

## 4. HTML Template — `productScreen4.html`

### 4.1 Price display on product cards

| Line | Element | Bindings |
|------|---------|----------|
| 152 | Header chip | `MRP: ₹{item.MRP}  \|\|  Unit Price: ₹{item.UnitPricePriceBook}` |
| 145–148 | Scheme ribbon | Shown when `item.hasApplicableSchemes` (secondary) |
| 163 | Applied scheme banner | `Final Price: ₹{item.discountedUnitPrice}  \|\|  Actual: ₹{item.UnitPricePriceBook}` |

### 4.2 Quantity inputs — Primary vs Secondary

**Primary** (lines 174–183):
```html
<template if:true={isPrimaryCustomer}>
    <lightning-input type="number" label="Cases"
                     data-id={item.id}
                     value={item.crateQty}
                     onchange={handleCrateQtyChange}>
    </lightning-input>
    <lightning-input type="number" label="Each"
                     data-id={item.id}
                     value={item.eachQty}
                     onchange={handleEachQtyChange}>
    </lightning-input>
</template>
```

**Secondary** (lines 186–191):
```html
<template if:false={isPrimaryCustomer}>
    <lightning-input type="number" label="EA"
                     data-id={item.id}
                     value={item.eachQty}
                     onchange={handleEachQtyChange}>
    </lightning-input>
</template>
```

### 4.3 Order summary table

| Line | Column | Source |
|------|--------|--------|
| 459–470 | Header (Primary includes "Case Qty") | `isPrimaryCustomer` toggle |
| 475 | Price column | `₹{item.unitPrice} * {item.displayQty}` |
| 476–477 | Tax | `item.taxAmt` |
| 478 | Net value | `item.netValue` |
| 516–518 | Grand totals row | `subTotalAmt`, `totalTaxAmt`, `grandTotalAmt` |

---

## 5. End-to-End Flow — Primary Order

```
1. User opens Order screen for a Primary Account
2. getData() → getSchemeWiseOrderData(visitId, accountId, orderId)
3. Apex resolves UnitPricePriceBook per product:
        Invoice price (≤30d) → Price_Book (Primary, this Account) → List Price
   Apex also returns deliveryPlant per product.
4. HTML renders each product card with MRP + UnitPricePriceBook.
5. User enters Cases + Each.
        handleCrateQtyChange / handleEachQtyChange
        → totalQty = cases * uomConversion + each
        → totalPrice = UnitPricePriceBook * totalQty
        → recalculateTotals()
   NO scheme logic runs.
6. setProducts() groups line items by Delivery Plant.
7. Summary table shows per-plant subtotal / tax / total + grand totals.
8. On save → upsertOrder():
        Unit_price__c                    = UnitPricePriceBook
        Before_Scheme_Unit_Price__c      = UnitPricePriceBook
        After_Scheme_Unit_Price__c       = UnitPricePriceBook
        Scheme_Item__c                   = null
        Tax_Amount__c, Total_Amount__c   = computed
```

---

## 6. End-to-End Flow — Secondary Order

```
1. User opens Order screen for a Secondary Account
2. getData() → getSchemeWiseOrderData(visitId, accountId, orderId)
3. Apex resolves UnitPricePriceBook per product:
        Price_Book (Customer=Account, Secondary)
        → Price_Book (Secondary_Customer_Category)
        → Price_Book (Sales_Channel)
   Then applies Price_Change__c override (MRP-based or UnitPrice-based %).
4. Apex also returns schemessss (scheme line items applicable to this account).
5. JS tags each product with hasApplicableSchemes + applicableSchemes[].
6. HTML renders cards with MRP, UnitPricePriceBook, and scheme ribbon.
7. User enters Each qty.
        handleEachQtyChange
        → syncQuantityToSchemeOffer()       // updates scheme selectedQty
        → autoSelectBestScheme()             // picks highest-discount scheme
              calculateSchemeBenefit() per scheme type
                 a) Free Product
                 b) Per-UOM discount
                 c) Sale-Value discount
        → sets discountedUnitPrice, discountedPrice, appliedScheme, schemeItemId
        → recalculateTotals()
8. setProducts() builds one "All Products" group, using discountedUnitPrice
   where a scheme is applied; totalDiscount is tallied.
9. Summary table shows price/tax/net, plus the saved discount line.
10. On save → upsertOrder():
        Unit_price__c                    = discountedUnitPrice (or UnitPricePriceBook)
        Before_Category_Slab_Unit_Price__c = pre Price_Change
        After_Category_Slab_Unit_Price__c  = post Price_Change
        Before_Scheme_Unit_Price__c      = UnitPricePriceBook
        After_Scheme_Unit_Price__c       = discountedUnitPrice
        Scheme_Item__c                   = Buy_Product__c Id
        Tax_Amount__c, Total_Amount__c   = computed on final unit price
```

---

## 7. Side-by-Side Comparison

| Aspect | Primary Order | Secondary Order |
|--------|---------------|-----------------|
| Price source priority | Invoice → PriceBook(Primary) → ListPrice | PriceBook(Account → Category → Channel) |
| Price override | None | `Price_Change__c` % off MRP or UnitPrice |
| Schemes | Not applied | Auto-applied (best-of) |
| Quantity input | Cases + Each | Each only |
| Summary grouping | By Delivery Plant | Single "All Products" |
| `deliveryPlant` populated | Yes | No |
| `discountedUnitPrice` | = `UnitPricePriceBook` | May be < `UnitPricePriceBook` |
| `Scheme_Item__c` saved | null | Buy_Product__c Id |
| Auto-recalc on qty change | Tax + totals only | Schemes + tax + totals |

---

## 8. Quick Reference — Key Line Numbers

**Apex `beatPlannerlwc.cls`**
- `getSchemeWiseOrderData` entry → 1481
- Primary product query → 1597
- Secondary product query → 1607
- Price hierarchy resolution → 1620–1705
- Price_Change application → 1553–1562, 1660–1676
- `productData` DTO → 4213–4248
- `upsertOrder` save → 2238, price fields 2553–2610

**LWC `productScreen4.js`**
- `getData` → 257
- Edit-mode quantity restore → 321–353
- Scheme availability flagging → 355–369
- `handleCrateQtyChange` → 1454
- `handleEachQtyChange` → 1477
- `syncQuantityToSchemeOffer` → 1508
- `autoSelectBestScheme` → 1578
- `calculateSchemeBenefit` → 1683
- `recalculateTotals` → 1784
- `setProducts` (Primary) → 1934–2019
- `setProducts` (Secondary) → 2052–2107

**LWC `productScreen4.html`**
- MRP / UnitPrice chip → 152
- Scheme ribbon icon → 145–148
- Applied-scheme banner → 163
- Primary qty inputs → 177–182
- Secondary qty input → 188–190
- Summary header → 459–470
- Summary rows → 475–478
- Grand totals → 516–518

---

## 9. Common Failure / Debug Points

1. **Unit price is 0 / blank** → no Price_Book row matched and `Product2.List_Price__c`
   is empty. Check the Account's `Customer_Type__c`, `Category__c`, `Sales_Channel__c`.
2. **Wrong price for Primary** → an Invoice exists in the last 30 days that
   overrides the Price Book. Confirm via `Invoice_items__r` for that product.
3. **Scheme not auto-applying** → `hasApplicableSchemes` was false (no matching
   `schemeOffer.lineItems[].productId`) or quantity hasn't crossed `minQty` /
   `saleValueThreshold`.
4. **Tax shown as 0** → `Product2.Tax__c` is blank.
5. **Delivery Plant grouping empty (Primary)** → `Price_Books__r[0].Delivery_Plant__c`
   not set on the Price Book record.
