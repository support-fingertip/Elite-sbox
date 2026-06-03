# QA Test Plan — Secondary Targets, Achievements & PBIS Incentives

| Field | Detail |
|---|---|
| Module | Secondary Sales Performance Management (DSM / SSA) |
| Coverage | Target Criteria Builder, Focus Pack Master, Secondary Target Manager, Achievement Engine, Incentive Slabs, PBIS Console |
| Version | 1.0 |
| Reference docs | BRD: Secondary Targets vs Achievement and PBIS; MDM Template: Secondary_target_Vs_Achiupload__MDM_Template_and_Report_Template |

---

## 1. Scope and assumptions

This plan covers end-to-end testing for the Secondary Targets module: setting up criteria, focus packs and per-user targets, running the daily achievement engine, configuring PBIS slabs, running the monthly PBIS computation and validating the per-user incentive breakdown.

**Out of scope:** Primary Targets / Primary PBIS / Primary Target_Plan flows; manual / flat-amount parameters such as Mobile Allowance, Stall Activity, TA/DA (next phase); PBIS approval workflow; payroll export integration.

---

## 2. Test environment prerequisites

| Item | Detail |
|---|---|
| Org | Elite SBOX 2026 (or a dedicated QA sandbox refreshed within the last 7 days) |
| Branch deployed | `claude/plan-target-incentives-YdaWv` (latest commit) |
| Test user profiles | one Admin, one Sales User (DSM-like, non-payroll), one TSE / Manager |
| Tabs visible | Target Criteria Manager, Focused Packs, Secondary Target Manager, Secondary PBIS Slabs, Secondary PBIS Console |
| Apex tests run before exploratory testing | `TAM_CalculationEngine_ServiceTest`, `TAM_AttendanceServiceTest`, `SecondaryAchievementBatchTest`, `SecondaryTarget_ControllerTest`, `SecondaryPBIS_ServiceTest`, `SecondaryPBIS_ControllerTest` — all must pass |

### 2.1 Permissions checklist

The QA user must have, at minimum:
- Read/Create/Edit/Delete on `Target_Criteria__c`, `Secondary_Target__c`, `Incentive_Slab__c`, `Incentive_Credit__c`, `Focused_Pack__c`, `Focused_Pack_Item__c`.
- Read on `Order__c`, `Order_Item__c`, `Daily_Log__c`, `Visit_Form__c`, `Account`, `Product__c`, `User`.
- FLS read/edit on all newly added fields on `Incentive_Slab__c` and `Incentive_Credit__c`.
- Apex class access: `TAM_TargetCriteria_Controller`, `SecondaryTarget_Controller`, `SecondaryPBIS_Controller`, `FocusedPackController`, `TAM_FieldMetadata_Service`.

### 2.2 Test data baseline (one-time setup)

Before running any test case, ensure the following exists in the org. If missing, create.

| Entity | Detail |
|---|---|
| Test DSM user | Active, channel = TN, IsActive = true. Note their **18-character User ID** for queries. |
| At least 5 active retailer Accounts (Customer_Type = Secondary Customer) | Used as outlets across orders. |
| At least 8 active Products | A mix that will populate Focus Packs (e.g. 4 SKUs labelled "Brownie variants", 4 SKUs labelled "Bakery & staples variants"). |
| Calendar reference month | Pick a closed month, e.g. **May 2026 (1-May to 31-May)**. All targets and orders below sit in that window. |

---

## 3. Test data fixtures — to seed via Workbench / DataLoader

| Object | Required rows | Comment |
|---|---|---|
| Daily_Log__c | 6 rows for the test user across days 1, 5, 10, 15, 20, 25 of the month. Set `Day_started_time__c` mid-day (12:00 local). Owner = test user. | These become attendance days for divisors. |
| Order__c (Secondary) | At least 8 orders for the test user. Mix of dates across the month and accounts. Set `Customer_Order_Type__c = 'Secondary Order'`, `Account__c` = retailer, `Order_Date__c` = date in month, `OwnerId` = test user. | Drives Revenue, UBO, TC, PC, TLSD, Focus Pack metrics. |
| Order__c (Primary) | 2 primary orders for the same user, in the same month. `Customer_Order_Type__c = 'Primary Order'`. | Used to verify the secondary filter correctly excludes these. |
| Order_Item__c | At least 25 line items across the secondary orders. Mix products from both packs. Populate `Each_Qyt__c` with realistic quantities (e.g. 6, 8, 12, 20). Populate `Total_Amount__c` and `Tax_Amount__c` so the formula `Non_Taxable_Order_Value__c` is non-zero. | Provides the raw achievement data. |
| Visit_Form__c | 4 visit forms in the month for the test user with `Secondary_Customer__c` set to outlets *not* present on orders. | Used to validate TC dedup-and-union logic. |

Recommended targets the user should hit when slabs are applied (helps QA know what to expect):

| Parameter | Target | Achievement aim |
|---|---|---|
| Cumulative Secondary Revenue | 1,00,000 | ~80,000 (i.e. 80%) |
| Cumulative UBO / ECO | 5 outlets | 4 |
| TC per day | 5 | ~4 |
| PC per day | 3 | ~2.5 |
| Average TLSD | 5 | ~4 |
| Focus Pack Revenue (Bakery) | 40,000 | ~50,000 (above 100%) |
| Focus Pack ECO (Bakery) | 3 | 2 |

Adjust quantities to land near these numbers so multiple slabs get exercised.

---

## 4. Module 1 — Target Criteria Builder

Path: **Target Criteria Manager** tab → `tamCriteriaBuilder` LWC.

### TC-CRIT-001 — Create a SUM criterion (Revenue)
**Steps**
1. Click **New Criteria**.
2. Step 1 — Name = `Sec Revenue`, Object = `Order_Item__c`, Category = `Revenue`.
3. Step 2 — Operator `SUM`, SUM Field `Non_Taxable_Order_Value__c`, Date Field `Order_Date__c`, User Field `Order_Owner_Id__c`.
4. Step 3 — Filter row: Field `Customer_Order_Type__c`, Operator `=`, Type `String`, Value `Secondary Order`.
5. Step 4 — Save.

**Expected**
- Record saved, appears in the list.
- Preview returns at least one row when the test user has secondary orders in the current month.

### TC-CRIT-002 — Create COUNT_DISTINCT (UBO / ECO)
**Steps**
1. Operator `COUNT_DISTINCT`, Distinct Field = `Account__c` (or `Order > Account` if line-level Account is null).
2. Same Date / User / Filter as TC-CRIT-001.

**Expected**
- Save succeeds. Preview returns distinct outlet count.

### TC-CRIT-003 — Create DAILY_UNIQUE_AVG with Visit Form union (TC per day)
**Steps**
1. Operator `DAILY_UNIQUE_AVG`, Distinct Field = `Account__c`.
2. Check **Use Attendance Divisor**.
3. Secondary Source Objects (JSON):
   ```json
   [{"object":"Visit_Form__c","userField":"OwnerId","dateField":"CreatedDate","distinctField":"CustomerId__c"}]
   ```

**Expected**
- Save succeeds. Preview returns a decimal value (distinct daily outlets / working days).

### TC-CRIT-004 — Create DAILY_UNIQUE_AVG (PC per day)
Like TC-CRIT-003 but **without** the Secondary Source JSON (orders only).

### TC-CRIT-005 — Create DAILY_LINES_PER_ORDER (Average TLSD)
**Steps**
1. Operator `DAILY_LINES_PER_ORDER`, Order Field = `Order__c`, Attendance Divisor checked.

**Expected**
- Save succeeds. Preview returns a decimal (lines / orders per day, averaged).

### TC-CRIT-006 — Create FOCUS_PACK_REVENUE
**Steps**
1. Operator `FOCUS_PACK_REVENUE`. Object = `Order_Item__c` (placeholder).
2. Step 2 — leave **Revenue Field** blank (defaults to `Non_Taxable_Order_Value__c`); leave Date/User blank (defaults).
3. Step 3 — add the secondary filter as in TC-CRIT-001.

**Expected**
- Save succeeds.

### TC-CRIT-007 — Create FOCUS_PACK_ECO
**Steps**
1. Operator `FOCUS_PACK_ECO`.
2. **Quantity Field** = `Each_Qyt__c`. **Outlet Field** = `Order > Account` (pick from the dropdown — the option should literally display as "Order > Account").
3. Step 3 — secondary filter as above.

**Expected**
- Save succeeds. Outlet Field dropdown contains both direct line fields and parent-relationship fields.

### TC-CRIT-008 — Field-level validation
**Steps**
1. Open any existing criterion and try to save with the Operator left blank.
2. Try SUM without a SUM Field.
3. Try DAILY_LINES_PER_ORDER without Order Field.

**Expected**
- The Next / Save button is disabled and the relevant inputs are highlighted as required.

### TC-CRIT-009 — Edit and Clone
**Steps**
1. Edit `Sec Revenue` — change Category and Save.
2. Use the Clone action on a criterion → verify a copy is created with `(Copy)` suffix and `Active = false`.

### TC-CRIT-010 — Toggle Active / Bulk Activate / Delete
**Steps**
1. Use the toggle on a row to deactivate.
2. Select multiple rows → Bulk Activate.
3. Delete a criterion that is linked to a target → expect the cascade message describing how many Target_Actual records will also be deleted.

---

## 5. Module 2 — Focus Pack Master

Path: **Focused Packs** tab → `New` opens `focusedPackForm` LWC.

### TC-FP-001 — Create a pack with Min Qty = 1
**Steps**
1. Name = `Bakery & staples`. Sales Channel = `TN`. Minimum Qualifying Quantity = `1`.
2. Filter by Category / Group as needed and select 4 SKUs via checkboxes.
3. Submit.

**Expected**
- Header `Focused_Pack__c` created. Four `Focused_Pack_Item__c` line items created with `SKU__c` populated.

### TC-FP-002 — Create a pack with Min Qty = 12 (Brownie example)
Repeat with Name `Brownie`, Min Qty `12`, four "Brownie variant" SKUs.

### TC-FP-003 — Duplicate name rejected
Try creating another pack named `Bakery & staples` → expect an error toast and no insert.

### TC-FP-004 — Empty SKU list rejected
Try saving with zero SKUs selected → expect an error.

---

## 6. Module 3 — Secondary Target Manager

Path: **Secondary Target Manager** tab → `secondaryTargetManager` LWC.

### TC-TGT-001 — Create non-focus-pack target (Revenue)
**Steps**
1. Click **New Target**. Type 2 letters of the test user's name → pick from suggestions.
2. Target Criteria = `Sec Revenue`. **Focus Pack picker should not be shown.**
3. Sales Channel = `TN`. Year = `2026`. Start Date = 1-May-2026. End Date = 31-May-2026.
4. Target Value = `100000`. Is Active = checked. Save.

**Expected**
- Toast `Secondary Target saved`. List refreshes with new row. `Target` autonumber assigned, `Focus Pack` column empty.

### TC-TGT-002 — Create focus-pack target
**Steps**
1. New Target → user search.
2. Criteria = `Focus Pack ECO`. **Focus Pack picker appears and is required.**
3. Pick `Bakery & staples`. Channel TN. Dates as above. Target Value = `3`.

**Expected**
- Save succeeds. Cannot save without choosing a Focus Pack (validation toast).

### TC-TGT-003 — Repeat for the remaining criteria
Create one Secondary Target per criterion you set up in Module 1 — Revenue, UBO/ECO, TC, PC, TLSD, Focus Pack Revenue, Focus Pack ECO. Each row should appear in the manager list.

### TC-TGT-004 — Filter by Criteria
Use the **Filter by Criteria** combobox → only matching rows appear. Reset to *All Criteria* → all rows reappear.

### TC-TGT-005 — Active-only toggle
Deactivate one target via Edit. Toggle **Active only** on → that row disappears. Toggle off → it returns.

### TC-TGT-006 — Recalculate one
Use the row action `Recalculate` on the Revenue target.

**Expected**
- Toast `Target recalculated`. Row's Achieved / % / Pending / Last Updated update synchronously.
- Verify the math: `Achieved` matches the SOQL `SELECT SUM(Non_Taxable_Order_Value__c) FROM Order_Item__c WHERE Customer_Order_Type__c='Secondary Order' AND Order_Owner_Id__c='<user 18-char id>' AND Order_Date__c BETWEEN 2026-05-01 AND 2026-05-31`.

### TC-TGT-007 — Recalculate All (batch)
Click **Recalculate All**.

**Expected**
- Toast `Achievement recalculation started …`. The batch enqueues. After ~1 min (or watching Apex Jobs), refresh the manager and verify all rows have updated `Last Updated`, `Achieved`, `%` and `Pending` values.

### TC-TGT-008 — Edit and Delete
1. Edit a target — change Target Value and Save → values update on the list.
2. Delete a target via row action → row removed.

### TC-TGT-009 — Summary tiles update
After Recalc All, the **Total / Active / Avg % Achievement** tiles at the top should reflect the new data.

---

## 7. Module 4 — Achievement engine validation

This section validates the math the engine produces. For each parameter, compute the expected number from raw SOQL and compare with the `Secondary_Target__c.Achievement_Value__c` after Recalculate.

### TC-CALC-001 — Secondary Revenue (SUM)
**Verification SOQL**
```sql
SELECT SUM(Non_Taxable_Order_Value__c) FROM Order_Item__c
WHERE Customer_Order_Type__c = 'Secondary Order'
  AND Order_Owner_Id__c = '<user id>'
  AND Order_Date__c >= 2026-05-01 AND Order_Date__c <= 2026-05-31
```
**Expected** — `Secondary_Target__c.Achievement_Value__c` for the Revenue target equals this SUM. % = Achieved / Target × 100.

### TC-CALC-002 — UBO / ECO (COUNT_DISTINCT)
**Verification SOQL**
```sql
SELECT COUNT_DISTINCT(Account__c) FROM Order_Item__c
WHERE Customer_Order_Type__c = 'Secondary Order'
  AND Order_Owner_Id__c = '<user id>'
  AND Order_Date__c >= 2026-05-01 AND Order_Date__c <= 2026-05-31
```
**Expected** — matches the Achievement Value.

### TC-CALC-003 — TC (DAILY_UNIQUE_AVG with Visit Form union)
**Manual check**
1. List distinct (date, account) tuples from secondary orders.
2. List distinct (date, `CustomerId__c`) tuples from visit forms for the period.
3. Union, dedup. Count tuples. Divide by working days (= rows in `Daily_Log__c` for that user where `Day_Started_Date__c` is non-null within the month — which is 6 in the seeded dataset).

**Expected** — `Achievement_Value__c` ≈ tuples / 6, rounded to 2 decimals.

### TC-CALC-004 — PC (DAILY_UNIQUE_AVG, no visit-form union)
Same as TC-CALC-003 but tuples come only from secondary orders. Verify Achieved = distinct (date, account) tuples / working days.

### TC-CALC-005 — Average TLSD (DAILY_LINES_PER_ORDER)
**Manual check**
1. Group secondary line items by `Order_Date__c`.
2. For each day, compute `(count of Order_Item rows that day) / (count of distinct Order__c that day)`.
3. Sum the daily ratios; divide by working days (6).

**Expected** — `Achievement_Value__c` equals the computed average to 2 decimals.

### TC-CALC-006 — Focus Pack Revenue
**Verification SOQL**
```sql
SELECT SUM(Non_Taxable_Order_Value__c) FROM Order_Item__c
WHERE Customer_Order_Type__c = 'Secondary Order'
  AND Order_Owner_Id__c = '<user id>'
  AND Order_Date__c BETWEEN 2026-05-01 AND 2026-05-31
  AND Product__c IN (SELECT SKU__c FROM Focused_Pack_Item__c
                     WHERE Focused_Pack__r.Name = 'Bakery & staples')
```
**Expected** — `Achievement_Value__c` equals the SUM.

### TC-CALC-007 — Focus Pack ECO (min qty per single order)
**Manual check**
1. For each secondary order containing at least one Bakery & staples SKU, sum `Each_Qyt__c` across the pack-SKU lines.
2. If sum >= pack `Minimum_Qualifying_Quantity__c`, count the outlet (per `Outlet Field` choice — line `Account__c` or parent `Order__r.Account__c`).
3. Take the **distinct outlet count** of qualifying orders.

**Expected** — `Achievement_Value__c` equals the distinct-outlet count.

### TC-CALC-008 — Primary orders excluded
Add a primary order with the same SKUs and date. Recalculate. Achievement values must **not** change (the criterion's filter `Customer_Order_Type__c = 'Secondary Order'` should exclude primary).

### TC-CALC-009 — Attendance divisor (no logs → 0)
Create a second test user with **no** `Daily_Log__c` entries but some secondary orders. Create TC / PC / TLSD targets for them. Recalculate.

**Expected** — TC / PC / TLSD Achievement = 0 because working days = 0. Revenue / UBO / Focus Pack should still calculate.

### TC-CALC-010 — Idempotency
Run `Recalculate All` twice in succession.

**Expected** — values stable; no duplicate rows; `Last Updated` advances.

---

## 8. Module 5 — Incentive Slabs (Single + Bulk)

Path: **Secondary PBIS Slabs** tab → `secondaryPbisSlabs` LWC.

### TC-SLAB-001 — Single New Slab
**Steps**
1. Click **New Slab**. Pick Target Criteria = `Sec Revenue`. Channel = `TN`. Compare On = `Percent`. From = `0`. To = `99.99`. Amount = `750`. Active = on. Save.

**Expected** — saved row appears in the list with the operator label resolved.

### TC-SLAB-002 — Focus-pack slab shows pack picker
Pick Criteria `Focus Pack ECO` → the **Focus Pack** combobox appears. Leave it blank for a generic slab; or pick `Brownie` to override that pack.

### TC-SLAB-003 — Validation
Try saving with no Criteria / no From / no Amount → expect a validation toast for each missing field.

### TC-SLAB-004 — Bulk Add — multiple criteria in one session
**Steps**
1. Click **Bulk Add**.
2. **Row 1** — Criterion `TC per day`, Channel TN, Pack disabled, Compare `Value`, From `5`, leave To blank, Amount `500`, Active.
3. **Row 2** — Click Clone on Row 1, change Criterion to `PC per day`, From `3`.
4. **Row 3** — Click Clone, Criterion = `Average TLSD`, From `5`.
5. **Row 4** — Add Row, Criterion = `Sec Revenue`, Compare `Percent`, From `0`, To `99.99`, Amount `750`.
6. **Row 5** — Clone Row 4, change to `100` – `105` Amount `1000`.
7. **Row 6** — Clone Row 5, change to `105.01`, To blank, Amount `1250`.
8. **Row 7** — Add Row, Criterion `Focus Pack ECO`, Channel TN, Pack blank (generic), Compare `Percent`, From `100`, Amount `250`.
9. **Row 8** — Clone Row 7, Criterion `Focus Pack Revenue`, Amount `250`.
10. Click **Save All**.

**Expected**
- Toast `Saved 8 slabs`. List refreshes and shows all eight, grouped by Criterion / Channel.
- The **Focus Pack** column in Row 1-6 is empty (n/a) and grey in the modal; in Row 7-8 it's editable.
- The **packDisabled** flag works dynamically when Criteria is changed within a row.

### TC-SLAB-005 — Bulk row Validation
In a fresh Bulk Add session, leave Row 1's Criterion blank and click Save All → validation toast `Row 1: pick a Target Criteria.` and no inserts.

### TC-SLAB-006 — Per-channel duplication
Use Clone on every TN row, change Channel to `AP` (or another value-set entry), keep everything else the same → after Save All, both channels' slabs co-exist.

### TC-SLAB-007 — Slab edit / delete
1. Edit an existing slab via row action → change amount and save → list updates.
2. Delete a slab via row action → list updates.

### TC-SLAB-008 — Filter
Use the top filter combobox **Filter by Criteria** and **Filter by Channel** → list narrows to matching rows. Active-only checkbox excludes inactive slabs.

---

## 9. Module 6 — PBIS Console (Run + Drill-down)

Path: **Secondary PBIS Console** tab → `secondaryPbisConsole` LWC.

### TC-PBIS-001 — Default month
On first open the Year and Month default to **the prior month** relative to today. *(This is intentional; the scheduled batch also runs for the prior month.)*

### TC-PBIS-002 — Run PBIS for the chosen month
**Preconditions** — Slabs (TC-SLAB-004) are in place and Recalculate All (TC-TGT-007) was executed for the same month.
**Steps**
1. Pick Year `2026`, Month `May`.
2. Click **Run PBIS for this Month**.

**Expected**
- Toast `Wrote N incentive row(s) for May 2026.` where N matches the number of slab matches.
- Top table shows the test user with Channel `TN`, Lines count and Monthly Total.
- Grand Total updates.

### TC-PBIS-003 — Drill-down
Click the row's chevron → **View breakdown**.

**Expected** — second table opens with one row per matched criterion:
- Criterion name, Type (operator), Focus Pack (if applicable), Compare, Achievement Value & %, Slab From / Slab To, Amount.
- Amount column sums to the user's Monthly Total.

### TC-PBIS-004 — Idempotent re-run
Click Run again for May → toast still shows the row count. SOQL on `Incentive_Credit__c` confirms there are no duplicates:
```sql
SELECT COUNT(Id) FROM Incentive_Credit__c
WHERE Source__c='Secondary PBIS' AND Year__c=2026 AND Month__c=5
```
Count should be the same as before; the prior rows were replaced.

### TC-PBIS-005 — Source filter
Verify the engine only touches Secondary PBIS rows; any existing rows with `Source__c='Primary'` or null are untouched.

### TC-PBIS-006 — Pack-specific slab wins
**Steps**
1. Add a pack-specific Focus Pack ECO slab for the **Brownie** pack paying `400` (alongside the generic `250` slab).
2. Run PBIS for May.
3. Open the user's breakdown.

**Expected**
- The Focus Pack ECO line for the Brownie target uses `400`.
- The Focus Pack ECO line for the Bakery & staples target still uses `250`.

### TC-PBIS-007 — Highest-From tiebreaker
Add overlapping Revenue slabs (e.g. From 0 To 200 = 500, From 100 To 105 = 1000, From 105.01 To null = 1250). At 110% the engine picks the highest qualifying `From` = the 1250 slab. Verify via the breakdown.

### TC-PBIS-008 — No matching slab → no row
Delete the Revenue slab tier that covers 80%. Run PBIS for May → the breakdown for that user shows no Revenue line and the total drops by the Revenue payout.

### TC-PBIS-009 — Year / Month change auto-refresh
Change the Year or Month dropdown → the totals table re-queries immediately (no manual Refresh required).

### TC-PBIS-010 — Empty state
Pick a month with no data → message `No incentive rows for <Month Year> yet. Click "Run PBIS for this Month" to compute.`

### TC-PBIS-011 — Async runner (Queueable)
Verify `SecondaryPBISQueueable` works:
1. Run anonymous Apex: `System.enqueueJob(new SecondaryPBISQueueable(2026, 5));`
2. Check Apex Jobs for the queueable completing.
3. PBIS rows for May exist in `Incentive_Credit__c`.

### TC-PBIS-012 — Scheduler
Verify the scheduler enqueues for the prior month:
```apex
System.schedule('PBIS QA Test', '0 0 2 1 * ?', new SecondaryPBISScheduler());
```
Then abort the test job from Scheduled Jobs.

---

## 10. End-to-end scenario (smoke test)

A complete cycle a QA engineer should run at least once.

1. **Configure** — Create the 7 criteria (Module 1) + 2 focus packs (Module 2).
2. **Seed** — Insert the test data fixtures (Section 3) for the chosen month.
3. **Target setup** — Create 7 Secondary_Target__c rows for the test user (Module 3).
4. **Run achievement engine** — Click Recalculate All in the Target Manager. Validate Achievement_Value / % / Pending against hand-calculations (Section 7).
5. **Slab setup** — Bulk Add the eight slabs (Section 8 TC-SLAB-004).
6. **PBIS run** — Open the PBIS Console, pick the month, click Run.
7. **Validate** — Open the breakdown for the test user. Confirm each line's amount matches the slab the achievement falls into. Sum equals the Monthly Total.
8. **Persistence check** — Run the SOQL:
   ```sql
   SELECT Executive__r.Name, Target_Criteria__r.Name, Focused_Pack__r.Name,
          Compare_On__c, Achievement_Value__c, Achievement_Percent__c,
          Credit_Amount__c, Matched_Slab__r.Achievement_From__c, Matched_Slab__r.Achievement_To__c
   FROM Incentive_Credit__c
   WHERE Source__c='Secondary PBIS' AND Year__c=2026 AND Month__c=5
     AND Executive__c = '<user id>'
   ORDER BY Target_Criteria__r.Name
   ```
   Each row should be self-consistent: the slab range covers the achievement, the amount equals the slab's `Incentive_Amount__c`.

---

## 11. Negative and edge cases

| ID | Case | Expected |
|---|---|---|
| EDGE-001 | Target with no Achievement (engine never ran) | PBIS computes 0 — no row inserted (achievement is null). |
| EDGE-002 | Target Start/End outside the run month | Excluded from PBIS for that month. |
| EDGE-003 | Inactive target (`Is_Active__c = false`) | Excluded from both Recalculate All and PBIS run. |
| EDGE-004 | Slab with Active = false | Ignored by the matcher. |
| EDGE-005 | Slab with To = null (unbounded) and value above From | Matches. |
| EDGE-006 | Slab with Sales_Channel blank | Applies to any channel; pack-specific (per TC-PBIS-006) still wins. |
| EDGE-007 | User without Sales_Channel set on the target | Only slabs with blank channel can match. |
| EDGE-008 | User with Secondary_Target__c rows in two channels | Console shows two rows (one per channel) for the same user. |
| EDGE-009 | `Order_Item__c.Account__c` is null and outlet lives on `Order__r.Account__c` | ECO criterion configured with Outlet Field = `Order > Account` returns correct distinct outlets. |
| EDGE-010 | Quantity field misconfigured (default Quantity__c, but data is in Each_Qyt__c) | ECO returns 0. Fix: set Quantity Field = `Each_Qyt__c` on the ECO criterion. |
| EDGE-011 | Filter operator `=` value typo (e.g. "Secondary order" lowercase) | Engine returns 0 because no rows match. Validate string matches the picklist value. |
| EDGE-012 | Run PBIS for a future month with no targets | 0 rows; no exceptions. |
| EDGE-013 | Year typed as 0 / Month outside 1-12 | Toast `Year and month (1-12) are required.` |
| EDGE-014 | Run PBIS for the same month twice in rapid succession | Idempotent — second run replaces, count unchanged. |
| EDGE-015 | Delete a Secondary_Target__c that has child Incentive_Credit__c records | `Secondary_Target__c` lookup on the credit becomes null (SetNull cascade). The credit row remains. |
| EDGE-016 | Delete a Target_Criteria__c that has slabs | Slab.Target_Criteria__c becomes null; the slab effectively no longer matches any target. |
| EDGE-017 | Empty bulk row list save | Toast `No slabs to save.` |

---

## 12. Regression checklist (after any code change to the module)

- Existing Primary incentive flow unaffected — verify any Primary `Incentive_Credit__c` rows still load on the Primary console (if any) and that new fields don't break legacy reports.
- `tamCriteriaBuilder` Step navigation works (Step 1 → 4) without console errors.
- `secondaryTargetManager` user-typeahead returns matches and selecting one populates the User lookup.
- All Apex tests still pass (`sf apex run test --tests TAM_CalculationEngine_ServiceTest,TAM_AttendanceServiceTest,SecondaryAchievementBatchTest,SecondaryTarget_ControllerTest,SecondaryPBIS_ServiceTest,SecondaryPBIS_ControllerTest`).
- Field-level security on the new `Incentive_Slab__c` / `Incentive_Credit__c` fields is accessible for the relevant profiles.
- Existing Focused Pack form still saves (`focusedPackForm`).

---

## 13. Defect reporting template

When QA logs a defect:

| Field | Value |
|---|---|
| Module | Criteria Builder / Focus Pack / Target Manager / Achievement Engine / Slabs / PBIS Console |
| Test case ID | e.g. TC-CALC-007 |
| Environment | Sandbox name + branch commit hash |
| Test user | Username + role |
| Steps to reproduce | Numbered list |
| Expected | What the spec / test case says |
| Actual | What happened, with screenshots |
| Severity | Blocker / Critical / Major / Minor |
| SOQL evidence | The query and result used to confirm the defect |

---

## 14. Sign-off criteria

| Section | Pass condition |
|---|---|
| All TC-CRIT cases | 100% pass |
| All TC-FP cases | 100% pass |
| All TC-TGT cases | 100% pass |
| All TC-CALC cases | 100% pass (math matches SOQL) |
| All TC-SLAB cases | 100% pass |
| All TC-PBIS cases | 100% pass |
| End-to-end smoke (Section 10) | Pass |
| Negative / edge (Section 11) | At least 80% pass; remaining must have product owner sign-off |
| Apex tests | 100% pass |

---

*End of document.*
