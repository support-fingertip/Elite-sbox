# Customer Master — Account Creation in Elite

> **Who this is for:** Anyone joining the Elite project with no prior context who needs to
> understand the **Customer Master** (how customers/accounts are created, approved, and how the
> data fits together) before making changes in the next phase.
>
> **What Elite is:** Elite is a Salesforce-based **Distribution Management System (DMS)**. It runs
> the flow of goods and money from the company, through distributors, down to retail outlets.
> The **Customer Master** is the heart of that system — every order, invoice, visit, target, and
> payment ultimately hangs off a customer record.

This document has **two sections**:

1. **[Section 1 — Creation & Functional Flow](#section-1--creation--functional-flow-with-navigations)**
   — what a customer is, Primary vs Secondary, how to create one, and the approval lifecycle.
   *(No technical knowledge needed.)*
2. **[Section 2 — Technical Reference](#section-2--technical-reference)**
   — the objects, Apex classes, triggers, and flows behind it. *(For developers.)*

> ⚠️ **Important note about this repository:** The Account object's own **field and record-type
> definitions are not stored in this repo.** Only the *logic* around customers lives here (Apex
> classes, the creation UI, related custom objects, and one Flow). Field names below are the ones
> referenced by that code/UI. For the authoritative, complete field list, retrieve the **Account**
> object directly from the Salesforce org.

---

## SECTION 1 — Creation & Functional Flow (with navigations)

*Audience: anyone. This section focuses on what a user sees and does.*

### 1.1 What is the Customer Master?

In Elite, a "Customer" is stored on the standard Salesforce **Account** object. A customer can be a
**distributor**, a **retailer / outlet**, or a **dealer** — essentially anyone the company sells to
or sells *through*.

The distribution chain looks like this:

```
   Company  ──(Primary sales)──►  Distributor  ──(Secondary sales)──►  Retailer / Outlet
```

- **Primary** = the company selling to its **distributors**.
- **Secondary** = a distributor selling onward to **retailers / outlets**.

Both the distributor and the retailer are stored as Account (customer) records — the difference is
the **customer type**, explained next.

### 1.2 Primary vs Secondary Customer (the core distinction)

The single most important field on a customer is **`Customer_Type__c`**. It has two values:

- **Primary Customer** — these are the upstream trade partners: **Distributors** and **Super Stockists**.
- **Secondary Customer** — these are the downstream points: **Outlets** and **Sub Stockists**.

Each value is automatically mapped to a matching **Record Type** of the same name when the customer
is created, which controls the page layout, required fields, and approval path.

| | **Primary Customer** | **Secondary Customer** |
|---|---|---|
| **Who they are** | **Distributor** or **Super Stockist** (billed/served directly by the company) | **Outlet** or **Sub Stockist** (served through the chain) |
| **Sales type** | Primary (company → distributor / super stockist) | Secondary (distributor or sub stockist → outlet) |
| **Parent link** | — (top of the chain) | Mapped to its parent **through Product Mapping**, *not* a Distributor lookup — see below |
| **Classification fields** | `Primary_Customer_Type__c`, `Primary_Customer_Business_Type__c` | `Secondary_Customer_Type__c`, `Secondary_Customer_Category__c` |
| **Money fields** | Bank details, `Payment_Type__c`, `Credit_Limit__c` | `High_Margin__c` |
| **Approval path** | Up to **Credit Dept. approval** (3 levels) | Up to **Level 2 approval** (2 levels) |
| **ERP / SAP sync** | Synced after credit approval & activation | Synced on creation and on activation |

#### Customer hierarchy & distribution flow

The same DMS supports **two distribution chains**, depending on whether goods flow through a
super-stockist tier:

```
 Chain A (direct):     Company ──► Distributor ─────────────► Outlets

 Chain B (two-tier):   Company ──► Super Stockist ──► Sub Stockist ──► Outlets
```

How each role maps to the customer type:

| Role | Customer Type | Position in the chain |
|---|---|---|
| **Distributor** | Primary Customer | Buys from the company, sells to **Outlets** |
| **Super Stockist** | Primary Customer | Buys from the company, supplies **Sub Stockists** |
| **Sub Stockist** | Secondary Customer | Buys from a Super Stockist, sells to **Outlets** |
| **Outlet** | Secondary Customer | The retail end-point (served by a Distributor or a Sub Stockist) |

> **Important — how parent↔child is actually stored.** In the Customer Master we do **not** use a
> `Distributor__c` lookup on the customer record to say "this outlet belongs to that distributor."
> Instead the **child → parent relationship is captured on the `Product_Mapping__c` object**, which
> is created during customer creation (the *Product Mapping* screen). Each mapping row links:
> - `Customer__c` → the customer being created (the **child** — an Outlet or Sub Stockist), and
> - `Primary_Customer__c` → its **parent** (the Distributor / Super Stockist), and
> - `Sub_Stockiest__c` → the intervening **Sub Stockist** when the chain is two-tier.
>
> So the hierarchy lives in **Product Mapping**, per product/territory context — *not* as a single
> distributor field on the Account. (All three of those fields are lookups to **Account**; see
> [Section 2.6](#26-related-objects-map-account-at-the-center).)

### 1.3 How to Create a Customer — step by step (the screens)

> The standard Salesforce "New / Edit Account" screen is replaced by a custom Elite wizard. The
> screens described below are the actual screens in the **`newCustomerLwc`** component
> (`force-app/main/default/lwc/newCustomerLwc`) — open its `.html` to see each field, and its `.js`
> for the navigation rules. The whole thing is a **pop-up wizard** with a heading that shows the
> current step and **Proceed** / **Previous** (or **Cancel** / **Save**) buttons at the bottom.

**Where the wizard goes (the screen sequence):**

```
                                           ┌─ Primary Customer ───────────┐
 [1] Customer Details ─► [2] Product Mapping┤                              ├─► [4] CCN Verification ─► Save
                                           └─ Secondary + On-Premises ─────┘            ▲
                                                                              [3] Photo Upload
                                           ┌─ Secondary, NOT On-Premises ──────────────────────────────────┐
                                           └────────────────────────► [4] CCN Verification ─► Save (no Photo)┘
```

> The exact path depends on **Customer Type** and the **On Customer Premises** toggle. Photo Upload
> and CCN Verification can also be **skipped automatically** for certain customer types / sales
> channels (driven by config), in which case the button becomes **Save** earlier.

---

**Screen 1 — Customer Details** *(`showAccountScreen`)*
Open the **New Customer** action; this is the first screen. It is organized into sub-sections:
- **Customer Information** — pick **Customer Type** (Primary/Secondary) first; the rest of the form
  reshapes itself. Then Name; for Primary: Customer Group + Primary type/business type; for
  Secondary: Secondary type/business type/category.
- **Contact Information** — Primary Phone (10-digit, required), Aadhaar, GST (required for Primary),
  Email, contact person details, PAN.
- **Bank Information & Reference Information** *(Primary only)* — company/owner name, security
  cheque, full bank account details, reference contacts.
- **Additional Information** — payment type, credit limit (Primary), payment term + high margin
  (Secondary), the **Beat** search/picker, and the **On Customer Premises** toggle.
- **Address Information** — state, district, city/town, pincode, street (required), plus door/
  building/landmark.

On **Proceed**, the screen validates the fields and runs a **duplicate-customer check** before
moving on.

**Screen 2 — Product Mapping** *(`showProductScreen`)*
Add one or more product-mapping rows (with add / clone / delete on each row):
- **Secondary** customers: pick the **Executive**, the parent **Primary Customer**, and optionally a
  **Sub Stockiest**.
- **Primary** customers: pick Executive, **Sales Channel, Territory, PDP Day, Sales Organization,
  Delivery Plant, Sales Office, Division, Order Type, Distribution Channel, Payment Term, Credit
  Description, Inco Terms**.

On **Proceed**, rows are validated; if **On Customer Premises** is on, the device **geo-location** is
captured here.

**Screen 3 — Photo Upload** *(`showCameraScreen`)*
Shown for **Primary** customers and for **Secondary** customers created **on the customer's
premises**. It embeds the **`customerFileUploadLwc`** component to capture/upload KYC photos &
documents (linked to the account via `UniqueFileId__c`).

**Screen 4 — CCN Verification** *(`showVerificationScreen`)*
A **Customer Confirmation Number (CCN/OTP)** is sent to the customer's primary mobile. The user
selects the number, clicks **Send CCN**, enters the code, and clicks **Verify CCN** (with a resend
timer). On success a confirmation screen appears and the **Save** button completes the process.
This step can be skipped automatically for certain customer types / sales channels.

**Final — Save & assign**
On the last step the **Proceed** button reads **Save**. Saving creates the customer in **Pending**
approval status; the customer is then assigned to a sales rep / employee
(`customerAssignment`) so it appears on their beat.

**What happens automatically when you save** (no manual action needed):

- The correct **Record Type** is set from the customer type.
- The **approvers** for this customer (L1 / L2 / credit) are filled in automatically based on the
  person who created the record.
- The record **owner** is set to an admin user.
- Uploaded documents are **linked** to the customer.
- The new customer is **queued to sync** to the external ERP/SAP system where applicable.

*(The mechanics behind this are in [Section 2.4](#24-accounttrigger).)*

### 1.4 Approval & Activation Lifecycle

Customer approval in Elite is a **custom status flow** — it is **not** a standard Salesforce
Approval Process. The status is tracked on the **`Approval_Status__c`** field and moves through these
stages:

```
                            ┌──────────────────► Level 2 Rejected
                            │
 Pending ──► Level 1 Approved ──► Level 2 Approved ──► Credit Dept. Approved
                                                  │
                                                  └──► Credit Dept. Rejected
```

**Who approves at each level** (stored on the customer record):

| Level | Role | Field on the customer |
|---|---|---|
| L1 | Area / Territory Sales Manager | `ASM_TSM__c` |
| L2 | Regional Sales Manager | `RSM__c` |
| L3 | Credit Department *(Primary only)* | `Primary_Customer_Approver_L3_Credit__c` |

**Rules that must be satisfied to advance:**

- **Secondary** customer: the **High Margin** value must be filled before reaching *Level 2 Approved*.
- **Primary** customer: **Payment Type** must be set, and if it's a **credit** customer the
  **Credit Limit** must be filled, before reaching *Credit Dept. Approved*.

**After credit approval (Primary):**

1. The **SAP team is notified**.
2. SAP creates the customer in the ERP and the **SAP Customer Code** (`SAP_Customer_Code__c`) is
   filled in.
3. An admin is notified to **activate** the customer.
4. The customer becomes **Active** (`Customer_Status__c = Active`) and is ready to transact.

In-app **notifications are sent at every stage** (submitted, approved, rejected) to the relevant
owner/approver.

**Deactivation guardrails:** A customer **cannot be deactivated** while their beat is currently being
worked, or while a visit to them is *In Progress*. This prevents pulling a customer out from under
active fieldwork.

### 1.5 Where the customer appears afterwards

Once a customer is active, it becomes the anchor for day-to-day operations — **Orders**, **Invoices**,
**Visits**, **Targets**, **Collections / payments**, **stock**, **claims**, and **schemes** all
reference the customer. The full list of related records is in
[Section 2.6](#26-related-objects-map-account-at-the-center).

---

## SECTION 2 — Technical Reference

*Audience: the developer making changes. Names, paths, and what each piece does.*

### 2.1 Component map (where things live)

| Concern | Folder | Open this for… |
|---|---|---|
| Trigger entry point | `force-app/main/default/triggers/` | When/what fires on Account DML |
| Business logic | `force-app/main/default/classes/` | The actual create/update rules & integration |
| Notifications | `force-app/main/default/flows/` | The approval-notification Flow |
| Creation / edit UI | `force-app/main/default/lwc/`, `force-app/main/default/aura/` | The custom screens |
| Related data model | `force-app/main/default/objects/` | The custom objects linked to Account |

### 2.2 UI components (LWC / Aura)

| Component | Path | Role |
|---|---|---|
| `newCustomerLwc` | `lwc/newCustomerLwc` | The new-customer creation form |
| `editAccountPage` | `lwc/editAccountPage` | The custom Account edit/create page body |
| `accountEditOverride` | `aura/accountEditOverride` | Aura wrapper that overrides the standard Account New/Edit action |
| `customerFileUploadLwc` | `lwc/customerFileUploadLwc` | Uploads supporting documents; ties files to the account via `UniqueFileId__c` |
| `customerAssignment` | `lwc/customerAssignment` | Assigns a customer to an employee / sales rep |
| `allAccountMap` | `lwc/allAccountMap` | Map view of customers |
| `secondaryCustomers`, `secondaryCustomerLookup`, `secondaryCustomerLedger`, `secondaryCustomerAgingReport` | `lwc/…` | Supporting views for secondary (retail) customers |

### 2.3 Apex classes

| Class | Path | Responsibility |
|---|---|---|
| `AccountTriggerHandler` | `classes/AccountTriggerHandler.cls` | All create / update / delete business logic for customers |
| `AccountController` | `classes/AccountController.cls` | Backend for the creation / edit UI |
| `AccountEditAccessController` | `classes/AccountEditAccessController.cls` | Controls who can edit a customer |
| `CustomerFileUploadController` | `classes/CustomerFileUploadController.cls` | Backend for the document upload component |
| `AzureAccountSyncQueue` | `classes/AzureAccountSyncQueue.cls` | Queueable job that syncs the customer to the external ERP / Azure (SAP) layer asynchronously |
| `AccountTriggerRecursion` | `classes/AccountTriggerRecursion.cls` | Recursion guard (e.g. `skipAzureCall` flag) |
| `CustomerReplacementController` | `classes/CustomerReplacementController.cls` | Handles customer replacement / transfer |
| `AccountCalendarController` | `classes/AccountCalendarController.cls` | Calendar/beat view for a customer |
| `PJPItemHandler` (`.deactivateBeats()`) | `classes/PJPItemHandler.cls` | Deactivates the customer's beats when the customer is deactivated |
| `SendEmailNotificationToBillingTeam` | `classes/SendEmailNotificationToBillingTeam.cls` | Emails the billing team on credit approval |
| `GenericNotificationCenter` | `classes/GenericNotificationCenter.cls` | Sends in-app notifications to SAP/System admins |

> Each class has a corresponding `*Test` class in the same folder.

### 2.4 AccountTrigger

**File:** `force-app/main/default/triggers/AccountTrigger.trigger`

- It fires on **before/after insert, before/after update, and after delete**.
- It is **gated by the custom label `ActivateAccountTrigger`** (set to `'True'` to enable) — useful
  for bulk loads / maintenance.
- It delegates almost all logic to **`AccountTriggerHandler`**.

What runs in each phase (functional summary — see the handler class for exact code):

| Phase | What happens |
|---|---|
| **before / after insert** | Assign Record Type from `Customer_Type__c`; auto-populate approvers (`ASM_TSM__c`, `RSM__c`, credit approver) from the creating user; set owner to admin; stamp `Customer_Activation_Date__c` if Active; link uploaded documents; queue ERP sync for Secondary customers; update the creator's Daily Log "new customers" count; copy `Customer_Code__c` → `Customer_Code_Text__c` |
| **before / after update** | Enforce approval gating rules (High Margin for Secondary; Payment Type / Credit Limit for Primary); stamp activation / inactivation dates; block unsafe deactivation (and call `PJPItemHandler.deactivateBeats()`); send SAP-admin / system-admin notifications on credit approval & SAP-code assignment; re-sync to ERP when relevant fields change |
| **after delete** | Adjust the creator's Daily Log customer count |

> **ERP / SAP integration touch-point:** `AzureAccountSyncQueue` is the async job that pushes the
> customer outward. Recursion into it is guarded by `AccountTriggerRecursion.skipAzureCall`.

### 2.5 Flows & Approval

- **`force-app/main/default/flows/Customer_Approval_Notification.flow-meta.xml`** — a
  **record-triggered Flow (after update)** on **Account**. It fires whenever **`Approval_Status__c`
  changes** and sends the appropriate in-app notification for each stage (Submitted, Level 1/2
  Approved, Rejected, Credit Dept. Approved/Rejected). This is the **only Account-related Flow** in
  the repo.
- **Approval Processes:** the only standard Approval Process in `force-app/main/default/approvalProcesses/`
  is for **`Product_Forecast__c`** — **not** for customers. Customer approval is driven by the
  trigger + this flow + the `Approval_Status__c` status field, **not** by a standard Approval Process.

### 2.6 Related-objects map (Account at the center)

The Account (customer) is the hub. Below are the main related custom objects grouped by domain, with
the field that links them back to Account.

> **Field-naming legend:** `Customer__c` / `Account__c` = the customer · `Distributor__c` /
> `Primary_Customer__c` = the distributor tier · `Store__c` / `Dealer__c` = the outlet ·
> `Sub_Stockiest__c` = a sub-distributor tier.

**Identity & territory**

| Object | Linking field | Purpose |
|---|---|---|
| `Employee_Customer_Assignment__c` | `Customer__c` | Assigns a customer to an employee / sales rep |
| `Junction_Beat__c` | `Account__c` | Many-to-many link between beats and customers |
| `Child_beat__c` | `Primary_Customer__c`, `Sub_Stockist__c` | Sub-territory beat assignment |
| `Visit__c` | `Account1__c`, `Distributor__c`, `Dealer__c` | A sales-rep visit to a customer |
| `Daily_Log__c` | `Account__c` | Daily activity / work log |

**Primary sales (company → distributor)**

| Object | Linking field | Purpose |
|---|---|---|
| `Order__c` | `Account__c` / `Distributor__c` / `Customer__c` | Primary order |
| `Invoice__c` | `Ship_To_Party__c` / `Store__c` | Primary invoice |
| `Return__c` | `Customer__c` / `Sub_Stockiest__c` | Primary return |
| `Credit_Note__c` | `Customer__c` | Primary credit adjustment |
| `Debit_Note__c` | `Customer__c` / `Distributor__c` | Primary debit adjustment |
| `Product_Mapping__c` | `Customer__c` (child) / `Primary_Customer__c` (parent) / `Sub_Stockiest__c` | Products a customer can transact **and the child→parent hierarchy** (this is where an Outlet/Sub-Stockist is tied to its Distributor/Super-Stockist — see [1.2](#customer-hierarchy--distribution-flow)) |
| `Price_Book__c` | `Customer__c` | Customer-specific pricing |

**Secondary sales (distributor → retailer)** — *these use Master-Detail to the customer*

| Object | Linking field | Purpose |
|---|---|---|
| `Secondary_Invoice__c` | `Customer__c` (Master-Detail) | Retailer invoice |
| `Secondary_Receipt__c` | `Customer__c` (M-D), `Distributor__c` | Retailer payment receipt |
| `Secondary_Credit_Note__c` | `Customer__c` (Master-Detail) | Secondary credit adjustment |
| `Secondary_Debit_Note__c` | `Customer__c` (Master-Detail) | Secondary debit adjustment |
| `Secondary_Advance_Receipt__c` | `Customer__c` (Master-Detail) | Advance payment from retailer |
| `Secondary_Retrun__c` | `Secondary_Customer__c` | Retailer return *(note: object name is spelled "Retrun")* |

**Targets & forecast**

| Object | Linking field | Purpose |
|---|---|---|
| `Target__c` / `Target_Item__c` | `Account__c` | Sales targets for a customer |
| `Secondary_Target__c` | — | Distributor→retailer targets |
| `TargetActuals__c` | `Customer__c` | Target-vs-actual tracking |
| `Product_Forecast__c` | `Distributor__c` | Demand forecast |

**Finance & operations**

| Object | Linking field | Purpose |
|---|---|---|
| `Collection__c` | `Customer__c` | Collection activity |
| `Outstanding__c` | `Account__c` | Outstanding receivables |
| `Payment_follow_up__c` | `Account__c` | Payment follow-up activity |
| `Claim__c` | `Customer__c` | Quality / warranty claims |
| `Outlet_Task__c` | `Account__c` | Task assigned at an outlet |
| `Sale__c` | `Account__c` | Sale transaction |
| `Sales_Strategy__c` | `Account__c` | Sales approach per customer |
| `Competition__c` | `Account__c` | Competitive intelligence at the customer |

### 2.7 Key Account fields reference (cheat-sheet)

> **Caveat:** these are fields **referenced by the code/UI**. The Account object's field metadata is
> **not in this repo** — retrieve the Account object from the org for the full authoritative list.

**Identity & codes**

| Field | Meaning |
|---|---|
| `Customer_Type__c` | Primary vs Secondary (drives record type & flow) |
| `Customer_Code__c` / `Customer_Code_Text__c` | Auto-generated internal customer code (+ text copy) |
| `SAP_Customer_Code__c` | ERP / SAP code, assigned after approval |
| `Customer_Group_Name__c` | Customer group classification |

**Status & approval**

| Field | Meaning |
|---|---|
| `Approval_Status__c` | Pending / Level 1 / Level 2 / Credit Dept. Approved / Rejected |
| `Customer_Status__c` | Active / Inactive |
| `Customer_Activation_Date__c` / `Customer_Inactivation_Date__c` | Status timestamps |
| `ASM_TSM__c`, `RSM__c`, `Primary_Customer_Approver_L3_Credit__c` | The approvers (L1 / L2 / credit) |
| `Customer_L1_Approver_Name__c`, `Customer_L2_Approver_Name__c` | Approver names used in notifications |

**Financial / KYC**

| Field | Meaning |
|---|---|
| `Payment_Type__c` | Credit / Cash |
| `Credit_Limit__c` | Credit line (required for credit customers, Primary) |
| `High_Margin__c` | Margin value (required for Secondary before L2) |
| `GST_Number__c`, `PAN_Number__c`, `Aadhaar_No__c` | Tax / KYC IDs |
| Bank fields (`Account_No__c`, `Bank_Name__c`, `IFSC_Code__c`, …) | Banking details (Primary) |

**Contact / address / integration**

| Field | Meaning |
|---|---|
| `Primary_Phone_Number__c`, `Secondary_Phone_Number__c`, `Email_ID__c` | Contact details |
| `State__c`, `District__c`, `Pincode__c`, `GeoLocation__c` | Location |
| `UniqueFileId__c` | Used to link uploaded documents to the account |
| `ERP_Check__c`, `ERP_Update__c`, `By_Pass_Validation__c` | ERP-sync control flags |
| `Distributor__c` | A distributor reference field on the Account. **Note:** the Customer Master does **not** rely on this to model the hierarchy — parent↔child is mapped via `Product_Mapping__c` (see [1.2](#customer-hierarchy--distribution-flow)). |

### 2.8 Glossary

| Term | Meaning |
|---|---|
| **Primary** | Company-to-distributor sales (and the distributor customer record) |
| **Secondary** | Distributor-to-retailer sales (and the retail/outlet customer record) |
| **Beat** | A defined route/round of customers a sales rep visits |
| **Sub-Stockist** | A sub-distributor tier between distributor and retailer |
| **ASM / TSM / RSM** | Area / Territory / Regional Sales Manager (the approval hierarchy) |
| **ERP / SAP sync** | Pushing customer data to the external finance/ERP system (via `AzureAccountSyncQueue`) |
| **KYC** | "Know Your Customer" — identity/compliance documents (GST, PAN, Aadhaar, bank) |
| **Activation** | The final step that makes an approved customer Active and able to transact |
