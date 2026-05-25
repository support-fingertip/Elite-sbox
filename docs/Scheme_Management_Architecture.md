# Scheme Management — Architecture & UI Design

> Status: **DRAFT for Solution Architect review.** No code to be written until sign-off.
> Source BRD: `Scheme Management BRD .docx` + Session 1 (19 May 2026) & Session 2 (21 May 2026) transcripts.
> Sample data: `KA QPS Slab (Overall Order Level and Plum Related Scheme).xlsx`, `KA_Schemes FY26-27.xlsx`, `TN Schemes.xlsx`, `West Q1 Schemss.xlsx`.

---

## Reference — Full ER Diagram

The full data model is shown below. **Section 1** (Scheme Product Group Creation) covers `Scheme_Product_Group__c` and `Scheme_Product_Group_Item__c` (top of the diagram); the remaining objects are covered in Sections 2–8 (still to be restructured — see the placeholder further down).

### ER Diagram

```mermaid
erDiagram
    Scheme__c }o--|| Scheme_Product_Group__c : "targets"
    Scheme__c ||--o{ Scheme_Slab__c : "has slabs"
    Scheme_Product_Group__c ||--o{ Scheme_Product_Group_Item__c : "contains"
    Scheme_Product_Group_Item__c }o--|| Product__c : "SKU"
    Area__c ||--o{ Territory__c : "contains"
    Order__c ||--o{ Order_Item__c : "lines"
    Order_Item__c ||--o{ Order_Item_Scheme__c : "applied"
    Order_Item_Scheme__c }o--|| Scheme__c : "of"
    Order_Item_Scheme__c }o--o| Scheme_Slab__c : "slab"
    Product__c ||--o{ Order_Item__c : ""
    Sales_Channel_To_SKU__c }o--|| Product__c : "gates"
```

Cascade levels (Region / Area / Territory / Outlet Category) are stored as fields directly on `Scheme__c` (see Section 3) — no separate junction object.

---

## Section 1 — Scheme Product Group Creation

> **Section format:** each section presents the new SObject(s) first, then a UI example as structured tables + a numbered interaction list, then a short explanation.

A **Scheme Product Group** is a named bundle of SKUs that one or more schemes can target. It exists so an admin can define a scheme once against many SKUs instead of one scheme per SKU. Groups are created at **Sales Channel** level (FR-005), and the `Group_Purpose__c` picklist controls which validation rules apply.

### 1.1 Object — `Scheme_Product_Group__c` (NEW)

The parent record for the bundle.

| Field | Type | Required | Notes |
|---|---|---|---|
| `Name` | Auto-number `SPG-{0000}` | system | display id |
| `Group_Label__c` | Text(120) | Yes | human label, e.g. "Cake-25g-MRP10" or "Atta-AnyPack" |
| `Sales_Channel__c` | Picklist (mirrors `Product__c.Channel__c`) | Yes | single-channel grouping (FR-005) |
| `Group_Purpose__c` | Picklist | Yes | `Price_Division` / `FOC_Qualifier` / `FOC_Free` |
| `MRP__c` | Currency(10,2) | Conditional | required **only when** `Group_Purpose__c = Price_Division` |
| `Net_Weight__c` | Number(10,2) | Conditional | required **only when** `Group_Purpose__c = Price_Division` (cakes); validates member uniformity |
| `Description__c` | Text Area | No | |
| `Is_Active__c` | Checkbox | No | defaults true |
| `Member_Count__c` | Roll-up COUNT | system | from `Scheme_Product_Group_Item__c` |

**Validation:**
- `Group_Purpose__c = Price_Division` → MRP + Net_Weight mandatory; trigger enforces `All_Members_Same_MRP__c` + `All_Members_Same_NetWeight__c` across child items.
- `Group_Purpose__c = FOC_Qualifier` / `FOC_Free` → MRP / Net_Weight may be null; uniformity check skipped (mixed-MRP / mixed-grammage SKUs allowed).

**Sharing:** Public Read/Write to `Scheme_Admin` permission set; Public Read-Only to all others.
**Volume:** ~500–1,500 groups org-wide. Custom index on `Sales_Channel__c + Group_Purpose__c + Is_Active__c`.

### 1.2 Object — `Scheme_Product_Group_Item__c` (NEW)

Junction between `Scheme_Product_Group__c` and `Product__c` — one row per SKU in the group.

| Field | Type | Required | Notes |
|---|---|---|---|
| `Scheme_Product_Group__c` | Master-Detail → `Scheme_Product_Group__c` | Yes | cascade delete with parent |
| `Product__c` | Lookup → `Product__c` | Yes | the SKU |
| `Unique_Key__c` | Text(80), External ID, Unique | system | formula `Scheme_Product_Group__c + '-' + Product__r.SKU_Code__c` |
| `Is_Active__c` | Checkbox | No | defaults true |

**Master-Detail rationale:** an item record is meaningless without its parent group, and the parent needs a `Member_Count__c` roll-up. Sharing inherits from the parent.
**Validation:** unique (`Scheme_Product_Group__c`, `Product__c`); a Product appears at most once per group.
**Volume:** ~80 items/group × 1,500 groups ≈ 120k rows org-wide.

### 1.3 UI Example — Scheme Group Builder

A single LWC page (`schemeProductGroupBuilder`) the admin lands on from the new **Scheme Product Groups** tab. The page has three areas — a **Header form**, a **Filter pane**, and an **SKU result grid** — followed by the save action. The header `Group Purpose` selection drives the visibility of MRP and Net Weight inputs and the live validation chip.

**Header form fields**

| Field | Widget | Required | Notes |
|---|---|---|---|
| Group Purpose | Radio: `Price_Division` / `FOC_Qualifier` / `FOC_Free` | Yes | drives MRP + Net Weight visibility and the validation chip |
| Group Label | Text input (max 120) | Yes | maps to `Group_Label__c` |
| Sales Channel | Picklist (single-select) | Yes | required first — gates the SKU catalogue |
| MRP | Currency input | Yes when `Price_Division` | hidden in FOC modes |
| Net Weight (g) | Number input | Yes when `Price_Division` (Cake category) | hidden in FOC modes |
| Description | Textarea (multi-line) | No | optional admin note |

**Filter pane** (narrows the SKU catalogue before selection)

| Filter | Widget | Notes |
|---|---|---|
| Category | Picklist | from `Product__c.Product_Category1__c` |
| Product Group | Picklist (dependent on Category) | from `Product__c.Group_Name__c` |
| Sub-group | Picklist | from `Product__c` sub-group field if present |
| Variant | Picklist | from `Product__c.Class__c` / `Flavors__c` |
| Grammage (g) | Picklist | from `Product__c.Net_Weight__c`; **advisory only in FOC modes** |
| MRP | Picklist | from `Product__c.MRP__c`; **advisory only in FOC modes** |

**SKU result grid columns**

| Column | Widget | Notes |
|---|---|---|
| Select | Checkbox | bulk-select via the "Select all filtered" action |
| SKU Code | Text (read-only) | `Product__c.SKU_Code__c` |
| Sku Name | Text (read-only) | `Product__c.Name` |
| Category | Text (read-only) | |
| Group | Text (read-only) | |
| Sub-group | Text (read-only) | |
| Grammage (g) | Number (read-only) | |
| MRP | Currency (read-only) | |

**User actions (in order)**

1. Admin opens the **Scheme Product Groups** tab and clicks **+ New Group**.
2. Admin picks a **Group Purpose**. The form re-renders: `Price_Division` shows MRP + Net Weight as required inputs; `FOC_Qualifier` / `FOC_Free` hide those fields.
3. Admin picks a **Sales Channel**. The SKU result grid loads SKUs gated by `Sales_Channel_To_SKU__c` for that channel.
4. Admin applies one or more **Filters** to narrow the grid (Category, Group, Sub-group, Variant, Grammage, MRP).
5. Admin ticks the SKUs to include — row-by-row, or via **Select all filtered**.
6. **Live validation chip** updates as the selection changes:
   - `Price_Division` mode — chip is **GREEN** when all selected SKUs share the same MRP and Net_Weight; **RED** otherwise with message *"Mixed MRP — group not allowed"*.
   - `FOC_Qualifier` / `FOC_Free` mode — chip is **INFO-GREEN** with message *"Mixed MRP / Weight allowed for FOC"*.
7. Admin clicks **Save as Group**. A modal prompts for the **Group Label**, then the page persists one parent `Scheme_Product_Group__c` plus one `Scheme_Product_Group_Item__c` per selected SKU in a single transaction.
8. On success the page redirects to a read-only view of the new group, showing member count and the actions **Edit (admin only)**, **Clone to new group**, **Deactivate**.

### 1.4 Explanation

The Scheme Product Group is the foundation that lets a single scheme cover many SKUs. The BRD (FR-001..FR-006) requires that a scheme be defined against a *group* of SKUs, not a single SKU, and that the admin be able to filter the catalogue by Category / Group / Sub-group / Variant / Grammage / MRP and "Select all".

Two further requirements drive the `Group_Purpose__c` picklist:

1. **Price-division uniformity (FR-006).** For Basic (X+Y), QPS, Order-Value and Plum schemes, the per-unit price reduction is redistributed across the qualifying quantity using a single MRP. Mixing SKUs of different MRP or grammage would break the redistribution. We enforce this with `Group_Purpose__c = Price_Division` — all members must share MRP + Net_Weight.

2. **FOC qualifying pools may be mixed (BRD Session 2).** The FOC example is *"buy 5 kg of Chakki Atta → get 200 g vermicelli per kg"*. The qualifying SKUs may span Atta 1 kg + 5 kg + 10 kg packs at different MRPs and grammages. We enforce this with `Group_Purpose__c = FOC_Qualifier`, which relaxes the uniformity rule. The *free* products are kept in a separate `FOC_Free` purpose group when there is a choice of giveaways (vermicelli OR oats); for a single-SKU giveaway a direct lookup is used (covered in Section 2 — Scheme Definition).

The group is **always** scoped to one **Sales Channel** (FR-005), so the same SKU may belong to different groups in different channels. A trigger on `Scheme_Product_Group_Item__c` enforces that the same SKU cannot appear in more than one *active* group of the **same** `Group_Purpose__c` within the **same** Sales Channel — preventing ambiguity when a scheme resolves "which group does this order line belong to".

Groups are referenced from `Scheme__c.Scheme_Product_Group__c` (covered in Section 2). Groups are never deleted — only deactivated — so historical orders that referenced an older group remain traceable.

---

## Section 2 — Scheme Definition (Master + Slabs)

> **Scope of this document:** the single-type-per-scheme model — one `Scheme__c` carries one `Primary_Scheme_Type__c` (one Basic OR one QPS OR one Order-Value, etc.). A separate document covering the multi-type variant (via an intermediate `Scheme_Item__c`) will be produced later.

A scheme is the master record. One `Scheme__c` has one `Primary_Scheme_Type__c` and one `Scheme_Product_Group__c`. To run Basic + QPS + Plum + Order-Value on the same group, create four parallel `Scheme__c` records — the calc engine applies them concurrently to each order line (see Section 4).

### 2.1 Object — `Scheme__c` (NEW)

| Field | Type | Required | Notes |
|---|---|---|---|
| `Name` | Text(255) | Yes | display name, e.g. "KA Cake QPS Q1 2026" |
| `Description__c` | Long Text | No | |
| `Sales_Channel__c` | Picklist | Yes | must match `Scheme_Product_Group__c.Sales_Channel__c` |
| `Scheme_Start_Date__c` | Date | Yes | |
| `Scheme_End_Date__c` | Date | Yes | only field admins can edit once `Is_Locked__c = true` (extend-only) |
| `IsActive__c` | Checkbox | No | toggled via the lifecycle flow |
| `Deactivation_Reason__c` | Text Area | No | required when `IsActive__c` flips true → false; captured by Field-Level History |
| `Primary_Scheme_Type__c` | Picklist (`Basic` / `QPS` / `FOC_Giveaway` / `Order_Value` / `Category_Value`) | Yes | drives the slab editor + calc engine |
| `Scheme_Product_Group__c` | Lookup → `Scheme_Product_Group__c` | Yes | the SKU bundle. For FOC, `Group_Purpose__c` must be `FOC_Qualifier`; for all other types, `Price_Division` |
| `Is_Locked__c` | Checkbox | system | flipped true on activation; blocks edits except `Scheme_End_Date__c` (extend), `IsActive__c`, and `Deactivation_Reason__c` |
| `Slab_Count__c` | Roll-up COUNT from `Scheme_Slab__c` | system | shown on list views |
| `Credit_Percentage__c` | Number | No | used by claim-credit posting |
| `Scheme_Eligibility_Percentage__c` | Number | No | used by claim-credit posting |
| **Cascade fields (8)** — full detail in Section 3 | — | — | 4 `Apply_to_All_*__c` checkboxes + 4 multi-select Long Text fields covering Region / Area / Territory / Outlet Category. **No separate `Scheme_Applicability__c` object** — cascade lives directly on `Scheme__c` |
| `Applicability_Summary__c` | Long Text(2000) | system | populated by after-save trigger when any cascade field changes; e.g. "Regions: KA, TN \| Areas: 5 \| Territories: All \| Outlet: GT" |

**Validation:**
- `Primary_Scheme_Type__c = FOC_Giveaway` → linked group's `Group_Purpose__c` must be `FOC_Qualifier`.
- All other `Primary_Scheme_Type__c` values → linked group's `Group_Purpose__c` must be `Price_Division`.
- `Scheme_End_Date__c >= Scheme_Start_Date__c`.
- When `Is_Locked__c = true`: only `Scheme_End_Date__c` (new ≥ old), `IsActive__c`, and `Deactivation_Reason__c` may change.
- Activation rejected unless ≥ 1 child `Scheme_Slab__c` exists and the cascade (Section 3) is configured at every level (Apply-All or specific list).

**Sharing:** Public Read-Only; writes gated by `Scheme_Admin` permission set.
**Audit:** Salesforce **Field-Level History** is enabled on `Scheme_End_Date__c`, `IsActive__c`, `Deactivation_Reason__c`, `Is_Locked__c`, `Primary_Scheme_Type__c`, and the cascade fields. No separate audit object — FLH provides the trail.
**Volume:** ~3,000 schemes/year. Indexes on `Sales_Channel__c + IsActive__c` and `Scheme_End_Date__c`.

#### ER fragment

```mermaid
erDiagram
    Scheme__c }o--|| Scheme_Product_Group__c : "targets"
    Scheme__c ||--o{ Scheme_Slab__c : "has slabs"
```

### 2.2 Object — `Scheme_Slab__c` (NEW)

The child object that holds every offer rule. A `Slab_Type__c` discriminates which subset of fields is used.

| Field | Type | Required | Notes |
|---|---|---|---|
| `Scheme__c` | Master-Detail → `Scheme__c` | Yes | cascade delete with parent |
| `Slab_Sequence__c` | Number(2,0) | Yes | stable display order; 1, 2, 3, … |
| `Slab_Type__c` | Picklist (`Basic` / `QPS` / `FOC_Giveaway` / `Order_Value` / `Category_Value`) | Yes | must match parent's `Primary_Scheme_Type__c` |
| `Qualifying_Qty_Min__c` | Number(8,0) | Conditional | min trigger qty in EA. Basic: the X (e.g. 11). QPS: the slab threshold (entered as cases in the UI; engine converts cases × `Product__c.Units_Per_Case__c` → EA at evaluation). FOC: minimum-to-qualify |
| `Qualifying_Qty_Max__c` | Number(8,0) | Conditional | inclusive upper for quantity-band Basic. Null = unbounded |
| `Qualifying_Value_Min__c` | Currency(12,2) | Conditional | slab lower bound on GSV (Order-Value) or category GSV (Category-Value) |
| `Qualifying_Value_Max__c` | Currency(12,2) | Conditional | inclusive upper; null = unbounded (top slab) |
| `Free_Qty__c` | Number(6,0) | Conditional | Y for Basic. For FOC, fixed free qty when `FOC_Ratio_Per_Qualifying_Unit__c = 1` |
| `Benefit_Per_Case__c` | Currency(8,2) | Conditional | per-case ₹ payout (QPS). Data-entry stays per-case; engine converts to per-EA at evaluation using `Product__c.Units_Per_Case__c` (default 1) — see §2.4 |
| `Benefit_Percent__c` | Percent(5,2) | Conditional | discount % for Order-Value / Category-Value |
| `FOC_Product__c` | Lookup → `Product__c` | Conditional | single fixed free SKU (simple FOC case) |
| `FOC_Product_Group__c` | Lookup → `Scheme_Product_Group__c` (`Group_Purpose__c = FOC_Free` only) | Conditional | pool of choosable free SKUs — "vermicelli OR oats" |
| `FOC_Ratio_Per_Qualifying_Unit__c` | Number(6,3) | Conditional | per-qualifying-unit multiplier — e.g. `0.200` = 200 g free per 1 kg bought. Default `1.000` |
| `Category__c` | Lookup → `Sales_Product_Category__c` | Conditional | required when `Slab_Type__c = Category_Value` |
| `Slab_Label__c` | Formula(text) | system | human label, e.g. "Basic · 11+1 (cycle)", "Basic · 11–20 → 1 free", "QPS-2 · 5 cases · ₹120/cs" |
| `Is_Active__c` | Checkbox | No | defaults true |

**Field usage by `Slab_Type__c`:**

| Slab_Type | Qty_Min | Qty_Max | Value_Min / Max | Free_Qty | Benefit_Per_Case | Benefit_Percent | FOC fields | Category | # slabs |
|---|---|---|---|---|---|---|---|---|---|
| `Basic` (cycle mode) | **Yes (X)** | — (null) | — | **Yes (Y)** | — | — | — | — | exactly 1 |
| `Basic` (band mode) | **Yes** | **Yes** (top may be null) | — | **Yes** (flat Y per band) | — | — | — | — | 1..N (non-overlapping bands) |
| `QPS` | **Yes** (threshold, cases) | — | — | — | **Yes** (per case → EA at eval) | — | — | — | 1..N (mutually exclusive thresholds) |
| `FOC_Giveaway` | **Yes** (min trigger) | — | — | optional (if ratio = 1) | — | — | **Yes** (Product OR Group + Ratio) | — | exactly 1 |
| `Order_Value` | — | — | **Yes** | — | — | **Yes** | — | — | 1..N (non-overlapping ranges) |
| `Category_Value` | — | — | **Yes** | — | — | **Yes** | — | **Yes** | 1..N per category |

#### Basic slab — two modes (engine auto-detects from data)

- **Cycle mode** — exactly 1 Basic slab with `Qualifying_Qty_Max__c` null. Classic X+Y repeating (FR-010). For qty Q: free count = `FLOOR(Q / X) × Y`. Any remainder gets no Basic benefit.
- **Band mode** — 1..N Basic slabs with `Qualifying_Qty_Min__c` and `Qualifying_Qty_Max__c` defining non-overlapping bands. For qty Q the engine picks the single band where Min ≤ Q ≤ Max (or Min ≤ Q if Max null) and gives that band's `Free_Qty__c` as a one-shot. Example: `11–20 → 1 free`, `21–50 → 2 free`, `51+ → 5 free` (top Max null).

#### Validation

- `Slab_Type__c` must match parent `Scheme__c.Primary_Scheme_Type__c`.
- `Slab_Sequence__c` unique per parent.
- Basic in cycle mode → exactly 1 slab with Max null on activation.
- Basic in band mode → all slabs have Min and Max populated (only the top slab may have Max null); bands must not overlap.
- QPS → thresholds unique within parent.
- Order-Value / Category-Value → value ranges must not overlap.
- FOC slab → exactly one of `FOC_Product__c` or `FOC_Product_Group__c` populated; when group is set, its `Group_Purpose__c` must be `FOC_Free`.
- Category_Value slab → `Category__c` mandatory.
- Once parent `Is_Locked__c = true`, no insert / update / delete of `Scheme_Slab__c` rows.

**Sharing:** Controlled by parent.
**Volume:** ~15,000 slab rows per year (avg ~5 per scheme).

### 2.3 UI Example — Scheme Definition Wizard

A multi-step LWC wizard (`schemeDefinitionWizard`) launched from the **Schemes** tab. Steps:

| Step | Owner section | Content |
|---|---|---|
| 1 — Master fields | §2.3 (this section) | Name, Primary Scheme Type, Sales Channel, dates, description |
| 2 — Link Product Group | Section 1 + §2.3 | reuses Section 1's group picker, filtered by `Group_Purpose__c` matching scheme type |
| 3 — Slabs | §2.3 (this section) | type-driven slab editor (five column variants) |
| 4 — Applicability Cascade | Section 3 | the 4-level cascade picker |
| 5 — Review + Activate | Section 6 (Lifecycle, pending) | conflict check + Activate button |

#### Step 1 — Master fields

| Field | Widget | Required | Notes |
|---|---|---|---|
| Scheme Name | Text input (max 255) | Yes | `Scheme__c.Name` |
| Primary Scheme Type | Radio: `Basic` / `QPS` / `FOC Giveaway` / `Order Value` / `Category Value` | Yes | drives Step 3 slab editor + Step 2 group filter |
| Sales Channel | Picklist | Yes | must match Product Group's channel |
| Start Date / End Date | Date pickers | Yes | End ≥ Start |
| Description | Textarea | No | |

#### Step 3 — Slabs editor

Five column-variant tables depending on `Primary_Scheme_Type__c`:

**Basic — cycle mode** (1 row)

| Column | Widget | Required | Maps to |
|---|---|---|---|
| Buy Qty (X) | Number input | Yes | `Qualifying_Qty_Min__c` |
| Max Qty | Number input (blank = cycle) | No | `Qualifying_Qty_Max__c` |
| Free Qty (Y) | Number input | Yes | `Free_Qty__c` |

> Example: Buy=11, Max=blank, Free=1 → "Repeats every 11+1".

**Basic — band mode** (multi-row)

> Example: `11–20 → 1 free`, `21–50 → 2 free`, `51+ → 5 free`.

**QPS**

| Column | Widget | Required | Maps to |
|---|---|---|---|
| Slab # | Auto | system | `Slab_Sequence__c` |
| Qualifying Cases | Number input | Yes | `Qualifying_Qty_Min__c` (cases; engine → EA at eval) |
| Benefit ₹/Case | Currency input | Yes | `Benefit_Per_Case__c` (per case; engine → per-EA at eval) |

> Example: `3 cases → ₹40/case`, `5 cases → ₹80/case`.

**FOC Giveaway** (1 row)

| Column | Widget | Required | Maps to |
|---|---|---|---|
| Min Qualifying Qty | Number input | Yes | `Qualifying_Qty_Min__c` |
| Free Product Source | Radio: `Single SKU` / `Choose from Group` | Yes | drives which lookup |
| FOC Product (Single SKU) | Lookup → `Product__c` | Yes (Single SKU) | `FOC_Product__c` |
| FOC Product Group | Lookup → `Scheme_Product_Group__c` (`FOC_Free`) | Yes (Pool) | `FOC_Product_Group__c` |
| Free Qty / Ratio | Number input | Yes | `Free_Qty__c` or `FOC_Ratio_Per_Qualifying_Unit__c` |

> Example (Atta): Min = 1000 g, Source = Single SKU = Vermicelli 200 g, Ratio = 0.200.

**Order Value**

| Column | Widget | Required | Maps to |
|---|---|---|---|
| Slab From (₹) | Currency input | Yes | `Qualifying_Value_Min__c` |
| Slab To (₹) | Currency input (blank = unbounded) | No | `Qualifying_Value_Max__c` |
| Discount % | Percent input | Yes | `Benefit_Percent__c` |

> Example: `5,000–20,000 → 5%`, …, `50,001+ → 11%`.

**Category Value (Plum)**

| Column | Widget | Required | Maps to |
|---|---|---|---|
| Category | Lookup → `Sales_Product_Category__c` | Yes | `Category__c` |
| Slab From (₹) | Currency input | Yes | `Qualifying_Value_Min__c` |
| Slab To (₹) | Currency input (blank = unbounded) | No | `Qualifying_Value_Max__c` |
| Discount % | Percent input | Yes | `Benefit_Percent__c` |

> Example: Cake — `50k–100k → 1%`, …, `200k+ → 2.5%`.

#### User actions (in order)

1. Admin clicks **+ New Scheme**.
2. Step 1: Name, type, channel, dates → Next.
3. Step 2: pick / create Product Group → Next.
4. Step 3: type-driven slab editor — add row(s) → Next.
5. Step 4: Applicability cascade (Section 3) → Next.
6. Step 5: Review + Activate (Section 6, pending).

### 2.4 Explanation

**FOC stays on `Scheme_Slab__c`.** A single child object with a `Slab_Type__c` discriminator keeps the calc engine, validation rules, UI, and read paths uniform across all five scheme types. The cost is a handful of conditional fields that only some types populate.

**`Benefit_Per_Case__c` → per-EA conversion (FR-013).** Business enters QPS payout as "₹X per case" because that's how schemes are negotiated; secondary billing is always in EA. The engine converts at evaluation time: `benefit_per_EA = Benefit_Per_Case__c / Product__c.Units_Per_Case__c` (defaulting `Units_Per_Case__c` to 1). The slab record stays in the business-friendly per-case form for reporting and audit.

**Basic in two modes.** FR-010 shows X+Y as the canonical Basic shape, and real operations also need flat quantity-band Basic ("buy 11–20 → 1 free, 21–50 → 2 free, 51+ → 5 free"). Both fit on `Scheme_Slab__c`: cycle mode is one slab with Max null; band mode is multiple slabs with Min + Max. The engine picks the mode from the data — no separate flag.

**Audit via Field-Level History (FLH), not a separate object.** Activate / Deactivate / Extend End Date / Clone are all captured naturally — Activate toggles `IsActive__c` and `Is_Locked__c`; Deactivate sets `IsActive__c = false` and requires `Deactivation_Reason__c`; Extend updates `Scheme_End_Date__c`; Clone creates a new `Scheme__c` (the relationship is implicit from the cloned record). FLH on the five Scheme__c fields above plus the cascade fields covers the trail.

---

## Section 3 — Applicability Cascade

A scheme targets a cross-product of four selectable cascade levels (after Sales Channel, which is already on `Scheme__c.Sales_Channel__c` from Section 2):

```
Sales Channel (on Scheme__c · Section 2)
  └─ Region          (multi-select, picklist values from Area__c.Region__c)
       └─ Area       (multi-select, filtered by selected Regions)
            └─ Territory   (multi-select, filtered by selected Areas)
                 └─ Outlet Category (multi-select, filtered by Sales Channel)
```

Each level supports an **"Apply to all"** flag. When the flag is true the level matches every value under it. All cascade selections are stored as **fields directly on `Scheme__c`** — no separate `Scheme_Applicability__c` junction object.

**Distributor is intentionally not a cascade level.** The org has ~20,000 customer (Distributor) Account records. Storing per-scheme distributor lists multiplies storage and breaks the "scheme applies broadly" mental model. The four-level cascade narrows to the right population; if a scheme genuinely needs to be limited to one named distributor, model it as a narrower Outlet Category.

### 3.1 Object — `Scheme__c` cascade fields (NEW, on the master)

Added to the `Scheme__c` field table from §2.1. Eight fields total — one Checkbox + one Long Text per cascade level.

| Field | Type | Required | Notes |
|---|---|---|---|
| `Apply_to_All_Regions__c` | Checkbox | No | when true, scheme matches every Region; `Regions__c` is ignored |
| `Regions__c` | Long Text(2000) | Conditional | semicolon-separated Region picklist values (e.g. `Karnataka;Tamil Nadu`); required when `Apply_to_All_Regions__c` is false |
| `Apply_to_All_Areas__c` | Checkbox | No | when true, all Areas under selected Regions match |
| `Areas__c` | Long Text(8000) | Conditional | semicolon-separated `Area__c` Ids; required when `Apply_to_All_Areas__c` is false |
| `Apply_to_All_Territories__c` | Checkbox | No | when true, all Territories under selected Areas match |
| `Territories__c` | Long Text(8000) | Conditional | semicolon-separated `Territory__c` Ids; required when `Apply_to_All_Territories__c` is false |
| `Apply_to_All_Outlet_Categories__c` | Checkbox | No | when true, all outlet categories valid for the Channel match |
| `Outlet_Categories__c` | Long Text(2000) | Conditional | semicolon-separated `Selling_Category__c` Ids; required when `Apply_to_All_Outlet_Categories__c` is false |

**Validation:**
- For each of the four levels, if `Apply_to_All_X__c = false` then the corresponding list field must be non-empty.
- Cross-level integrity check at save: selected Areas must belong to the selected Regions; selected Territories must belong to the selected Areas. (`Apply_to_All` at a parent level satisfies the integrity for children below it.)
- Activation rejected unless every level has either `Apply_to_All_X__c = true` OR a non-empty list.

**Why Long Text rather than multi-select picklist:** Areas / Territories / Outlet Categories are records, not picklist values. Salesforce multi-select picklists cap at 1000 values and don't track FK integrity to records anyway. A Long Text storing semicolon-separated Ids, paired with the LWC selector in §3.3, is the simplest pattern that scales (the selector re-validates Ids on save; the engine silently drops orphaned Ids at evaluation time, so a deleted Area causes the scheme to stop applying rather than crash).

### 3.2 Object — `Territory__c` (NEW)

A new custom object subordinate to `Area__c`. Each Territory belongs to one Area; admins maintain Territory records as master data.

| Field | Type | Required | Notes |
|---|---|---|---|
| `Name` | Auto-number `TRY-{0000}` | system | display id |
| `Territory_Name__c` | Text(120) | Yes | human label, e.g. "Bangalore Urban North" |
| `Area__c` | Master-Detail → `Area__c` | Yes | parent area |
| `Is_Active__c` | Checkbox | No | defaults true |

**Master-Detail rationale:** territories belong to an area; cascade delete is acceptable; sharing follows parent.
**Volume:** ~3–10 territories per Area; org-wide estimate < 1,000 records.

### 3.3 UI Example — Cascade Picker (Wizard Step 4)

Step 4 of the Scheme Definition Wizard renders four cascade rows. Each row drives the next: picking Regions filters the Area selector; picking Areas filters the Territory selector. Outlet Category is filtered only by the scheme's Sales Channel.

**Cascade row fields (one row per level)**

| Level | Apply-All widget | Specific-values widget | Backed by |
|---|---|---|---|
| Region | Checkbox | Multi-select picklist (values from `Area__c.Region__c` picklist) | `Apply_to_All_Regions__c` + `Regions__c` |
| Area | Checkbox | Multi-select chip selector (LWC; options filtered to Areas whose Region ∈ selected Regions) | `Apply_to_All_Areas__c` + `Areas__c` |
| Territory | Checkbox | Multi-select chip selector (LWC; options filtered to Territories whose Area ∈ selected Areas) | `Apply_to_All_Territories__c` + `Territories__c` |
| Outlet Category | Checkbox | Multi-select chip selector (LWC; options filtered to `Selling_Category__c` rows for the scheme's Channel) | `Apply_to_All_Outlet_Categories__c` + `Outlet_Categories__c` |

**User actions (in order)**

1. Sales Channel is already picked in Step 1 (Section 2) and shown read-only at the top of Step 4.
2. Admin picks **Regions** — either ticks "Apply to All" or selects one or more values.
3. **Area** selector enables once Regions are set, with options filtered. Admin ticks "Apply to All" or selects.
4. **Territory** selector enables once Areas are set, with options filtered. Admin ticks "Apply to All" or selects.
5. **Outlet Category** selector is independent of the geographic levels but constrained to the Channel's valid categories. Admin ticks "Apply to All" or selects.
6. **Applicability summary preview** updates live below the picker (e.g. "Channel: GT · Regions: KA, TN · Areas: 5 · Territories: All · Outlet: GT, Club").
7. On Save the validation rule ensures each level has either `Apply_to_All_X__c = true` or ≥ 1 specific value.

### 3.4 Explanation

**Cascade lives on `Scheme__c`, not in a junction.** Eight fields on the master vs. ~12 child records per scheme. The trade-off:
- ✅ Flat data model — no second-level query at evaluation time.
- ✅ Single-record validation; cascade integrity is one Apex trigger on `Scheme__c`.
- ✅ Field-Level History on the cascade fields gives the audit trail for free.
- ❌ No referential integrity on Area / Territory / Outlet Category Ids (mitigated by LWC re-validation on save and benign orphan-Id behaviour at evaluation time).

**Cascade resolution at order-capture time.** For each order line, the calc engine reads the order's Channel, the Distributor's Area and Territory (from `Account` standard fields), and the customer's Outlet Category. It then matches each scheme's cascade fields:
- Region: matches if `Apply_to_All_Regions__c` is true, **or** Distributor's Area's Region ∈ `Regions__c`.
- Area: matches if `Apply_to_All_Areas__c` is true, **or** Distributor's Area Id ∈ `Areas__c`.
- Territory: matches if `Apply_to_All_Territories__c` is true, **or** Distributor's Territory Id ∈ `Territories__c`.
- Outlet Category: matches if `Apply_to_All_Outlet_Categories__c` is true, **or** customer's Outlet Category Id ∈ `Outlet_Categories__c`.

A scheme is eligible only when **all four levels match** (AND of cascade levels). The (Channel, Region, Area, Territory, Outlet Category) tuple is cached for repeated orders (Scalability, pending).

---


## Section 4 — Multi-Scheme Calculation Logic

This section describes how the four scheme types stack on an order, plus the two objects / field-sets that record the applied results.

### 4.1 Where applied schemes are persisted

- **Per-line schemes** (Basic, QPS, Plum, FOC link) — recorded as `Order_Item_Scheme__c` rows on the corresponding `Order_Item__c`. They reduce the per-EA unit price on that line.
- **Order-Value** — recorded as fields directly on `Order__c`. It is a **flat ₹ discount on the order grand total** and does **not** modify per-line unit prices. Only one Order-Value scheme can match a given order at a time (activation-time validation enforces this).

#### Object — `Order_Item_Scheme__c` (NEW)

One row per applied per-line scheme.

| Field | Type | Notes |
|---|---|---|
| `Order_Item__c` | Master-Detail → `Order_Item__c` | cascade with line |
| `Scheme__c` | Lookup → `Scheme__c` | the source scheme |
| `Scheme_Slab__c` | Lookup → `Scheme_Slab__c` | which slab fired |
| `Sequence__c` | Number(2,0) | 1 = Basic, 2 = QPS, 3 = Plum, 4 = FOC link |
| `Scheme_Snapshot_Type__c` | Text(40) | hardcopy of `Slab_Type__c` at order time |
| `Benefit_Amount__c` | Currency(10,2) | total ₹ benefit on this line from this scheme |
| `Per_Unit_Discount__c` | Currency(8,4) | per-EA price reduction this scheme contributes |
| `Free_Qty__c` | Number(6,0) | Y (Basic) or FOC giveaway qty |
| `Qualifying_Qty__c` | Number(8,0) | portion of line qty consumed by this slab |
| `Notes__c` | Long Text(2000) | calc trail |

- **Sharing:** Controlled by parent.
- **Validation:** unique (`Order_Item__c`, `Scheme__c`, `Scheme_Slab__c`).
- **Volume:** ~3–5× `Order_Item__c`.

#### New fields on `Order__c` for Order-Value

A single set of fields on the order header — not a junction. Only one Order-Value scheme applies per order.

| Field | Type | Notes |
|---|---|---|
| `Order_Value_Scheme__c` | Lookup → `Scheme__c` | the Order-Value scheme that fired; null if none |
| `Order_Value_Slab__c` | Lookup → `Scheme_Slab__c` | which slab fired |
| `Order_Value_GSV__c` | Currency(12,2) | the gross GSV used for qualification (audit) |
| `Order_Value_Discount_Percent__c` | Percent(5,2) | the % that fired |
| `Order_Value_Discount_Amount__c` | Currency(10,2) | flat ₹ deducted from the order grand total |

#### Roll-up fields used by the order summary

| Object | Field | Type | Notes |
|---|---|---|---|
| `Order_Item__c` | `Total_Scheme_Benefit__c` | Roll-up SUM from `Order_Item_Scheme__c.Benefit_Amount__c` | per-line total benefit (Basic + QPS + Plum + FOC) |
| `Order__c` | `Line_Scheme_Benefit_Total__c` | Roll-up SUM from `Order_Item__c.Total_Scheme_Benefit__c` | sum across all lines |
| `Order__c` | `Grand_Total_After_Schemes__c` | Formula (currency) | `Line GSV total − Line_Scheme_Benefit_Total__c − Order_Value_Discount_Amount__c` |
| `Order__c` | `Scheme_Eval_Status__c` | Picklist (Pending / Computing / Computed / Stale / Error) | drives async re-evaluation |
| `Order__c` | `Scheme_Eval_Timestamp__c` | DateTime | last successful eval |

### 4.2 Application order

| # | Stage | Computed on | Effect |
|---|---|---|---|
| 1 | **Basic** (X+Y or band) | Gross MRP per EA | per-line unit price reduction (writes `Order_Item_Scheme__c` row) |
| 2 | **QPS** | Basic-adjusted unit price (FR-014) | per-line unit price reduction on top of Basic |
| 3 | **FOC Giveaway** | Qualifying line quantity | new synthetic `Order_Item__c` line at ₹0.01 with its own `Order_Item_Scheme__c` link; the qualifying line is unchanged |
| 4 | **Plum (Category Value)** | Category gross GSV (sum of MRP × Qty for that category) | discount % applied as a **per-EA unit price reduction** on each line in the category (allocated proportionally to each line's gross GSV share within the category) |
| 5 | **Order-Value** | Order gross GSV (sum of MRP × Qty across all lines) | **flat ₹ discount on the order grand total only** — per-line unit prices are NOT modified |

**Key rules:**

- **QPS computes on the Basic-adjusted unit price** (FR-014), not on gross MRP.
- **Plum computes on category gross GSV** (FR-042) but is **applied per-line** — it reduces the unit price on every line in that category, so the per-EA rate the customer pays reflects the Plum discount.
- **Order-Value computes on order gross GSV** (FR-042) and is **applied at the order header only** — it appears as a separate header-level line in the order summary panel; per-line unit prices stay at their post-Plum values.

### 4.3 Worked example

**Setup:**

- Line of interest: SKU `EL-00121` (Marble Cake, Cake category), MRP = ₹10, ordered Qty = 36 EA, `Units_Per_Case` = 12.
- Order also has other lines totalling ₹3,240 gross (mix of Cake and Biscuit); the line of interest is ₹360 gross. Order grand gross = ₹3,600. Cake-category gross = ₹360 (this line is the only Cake line).
- Scheme stack (all eligible after cascade resolution):
  - **Scheme A — Basic 4+1.** One Basic slab: `Qualifying_Qty_Min = 4`, `Free_Qty = 1`, `Qualifying_Qty_Max = null` (cycle mode).
  - **Scheme B — QPS.** Slabs: `3 cases → ₹12/case`, `5 cases → ₹30/case`. Line is exactly 3 cases → matches the 3-case slab. Per-EA benefit = `12 / 12 = ₹1`.
  - **Scheme C — Plum Cake 1%.** Slab: `0–unbounded → 1%`. Applied per-line for Cake-category lines.
  - **Scheme D — Order-Value 2%.** Slab: `₹3,000+ → 2%`. Applied flat at order header.

**Per-line walk-through for the line of interest:**

| Step | Operation | Numbers | Effective unit price |
|---|---|---|---|
| 0 | Gross at MRP | `10.00` | **₹10.00** |
| 1 | Basic 4+1 (cycle): `MRP × X / (X+Y)` = `10 × 4 / 5` | `= 8.00` | **₹8.00** |
| 2 | QPS 3-case slab: subtract `Benefit_Per_Case / Units_Per_Case = 12 / 12 = 1.00` per EA from the Basic-adjusted price | `8.00 − 1.00` | **₹7.00** |
| 3 | (no FOC giveaway in this example) | — | ₹7.00 |
| 4 | Plum Cake 1%: total Plum discount on the Cake category = `0.01 × 360 = ₹3.60`. This line's share = `(360 / 360) × 3.60 = ₹3.60`. Per-EA = `3.60 / 36 = ₹0.10` | `7.00 − 0.10` | **₹6.90** ← final per-line unit price |
| 5 | Order-Value 2%: flat header discount = `0.02 × 3,600 = ₹72.00`. Posted to `Order__c.Order_Value_Discount_Amount__c`. **Per-line unit price unchanged.** | — | ₹6.90 (unchanged) |

**Final per-EA unit price for this line = ₹6.90.** Line value = `6.90 × 36 = ₹248.40`.

**Order total computation:**

```
Sum of line values after Basic + QPS + Plum   = ₹248.40 + (other lines' post-line-scheme totals)
                                              − ₹72.00   (Order-Value flat header discount)
                                              = Order grand total
```

### 4.4 Persistence — what gets written

**Per-line, on `Order_Item__c` (for the line of interest):**

| # | Order_Item_Scheme__c | Scheme | Slab | Per-Unit Discount | Line Benefit |
|---|---|---|---|---|---|
| 1 | Basic | the Basic 4+1 slab | ₹2.00 | ₹72.00 |
| 2 | QPS | the 3-case slab | ₹1.00 | ₹36.00 |
| 3 | Plum Cake | the 0–∞ Cake slab | ₹0.10 | ₹3.60 |

`Order_Item__c.Total_Scheme_Benefit__c` (roll-up SUM) = **₹111.60** for this line.

**Order-Value on `Order__c`** (single set of fields, not a junction row):

| Field | Value |
|---|---|
| `Order_Value_Scheme__c` | Scheme D |
| `Order_Value_Slab__c` | the `₹3,000+ → 2%` slab |
| `Order_Value_GSV__c` | ₹3,600.00 |
| `Order_Value_Discount_Percent__c` | 2.00 % |
| `Order_Value_Discount_Amount__c` | ₹72.00 |

`Order__c.Grand_Total_After_Schemes__c` = `Line GSV total − Line_Scheme_Benefit_Total__c − Order_Value_Discount_Amount__c`.

### 4.5 Edge cases

- **No QPS qualification.** Line qty < smallest QPS threshold → no QPS row is written; Plum and Order-Value still apply on gross.
- **QPS slab decomposition (FR-015).** A line of 8 cases against slabs `3 / 5 / 10` → engine writes **two** QPS rows: one for the 5-case lot, one for the 3-case lot. The 0-case remainder gets no QPS.
- **Plum applies only to lines in the configured category.** Lines outside the category get no Plum row.
- **Only one Order-Value scheme per order.** Activation-time validation prevents two competing Order-Value schemes from being active in the same Channel × Region × Area × Territory × Outlet Category combination. If somehow two are eligible, the engine picks the one with the larger `Order_Value_Discount_Amount__c` and flags `Scheme_Eval_Status__c = Error`.
- **FOC giveaway never reduces the qualifying line's unit price.** The free product is a separate synthetic `Order_Item__c` at ₹0.01 with its own `Order_Item_Scheme__c` link; the qualifying line keeps its full Basic + QPS + Plum treatment.
- **Concurrent QPS schemes targeting the same SKU.** Disallowed by activation-time validation (one active QPS per SKU per Channel × Area × Outlet Category combination). Two competing QPS schemes never reach the engine simultaneously.

---

## Next iterations

This document covers the **single-type-per-scheme** model (one `Primary_Scheme_Type__c` per `Scheme__c`). A sibling document for the multi-type variant (via an intermediate `Scheme_Item__c`) will be produced later.

Future sections to be added to this document, in the same Object → UI Example → Explanation format:

- **Section 5 — Order Capture & Application** — the order capture LWC, the per-line "applied schemes" expander, the header scheme summary panel, the `Scheme_Eval_Status__c` lifecycle.
- **Section 6 — Lifecycle** — activate / extend / deactivate / clone flows, Field-Level History audit trail.
- **Section 7 — Calc Engine Internals** — the `SchemeEvaluationService` Apex class signatures, the cascade-cache key strategy, batch re-evaluation.
- **Section 8 — Reporting & Claim Posting** — claim-credit ledger updates, BI-friendly summary views.
- **Section 9 — Scalability & Security** — volume sizing, archival, permission set, sharing.
