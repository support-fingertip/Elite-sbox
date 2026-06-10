# PBIS Target — data upload via Salesforce Inspector

Files (in `scripts/import/`):
- **PBIS_Target_Import_Template.xlsx** / **.csv** — the upload template.
  - **Row 1** = field API names (the header Salesforce Inspector reads).
  - **Row 2** = description of each field (guidance only).
  - **Row 3** = a sample row showing the expected shape.

## Before importing
Salesforce Inspector treats **row 1 as the header and every following row as data**.
So **delete the description row (row 2)** — and the sample row (row 3) if you don't
want it created — and put your real data starting at row 2 before you import.

## Columns
- `External_Id__c` — unique upsert key per row (e.g. `EMP1001-2026-04-Monthly`).
- `User__r.Username` — sets the `User__c` lookup by the user's Salesforce Username
  (Username is an ID-lookup field, so Inspector resolves it). Gross Salary and Profile
  derive from this user automatically.
- `PBIS_Policy__c` — the PBIS Policy **record Id** (copy from the Policy record). The
  Policy `Name` is not an ID-lookup field, so use the Id here.
- `S_D_Parameter_<n>__r.External_Id__c` — sets slot `n`'s parameter by its External Id
  (e.g. `Bulk Depot | Total Volume Achievement`). Leave a slot's three columns blank
  if that slot is unused.
- `S_D_Parameter_<n>_Weightage__c` / `_Target__c` — weightage % and target for slot `n`.
  Used-slot weightages must total **100**.

**Not in the template (do not upload):**
- `Gross_Salary__c` — auto-filled from the User on save.
- `Profile__c`, `Designation__c`, `Total_Weightage__c`, `Has_Mandatory_Parameter__c` — formulas.
- All Task-4 calc fields (`..._Achievement__c`, `..._Achievement_Percent__c`,
  `..._Qualified_Slab__c`, `..._Incentive_Amount__c`, `Total_Incentive_Value__c`,
  `Max_Incentive_Value__c`, `Is_Eligible__c`, `Validation_Message__c`) — system-computed.

## Steps (Salesforce Inspector → Data Import)
1. Open **Salesforce Inspector** → **Data Import**.
2. Object: **PBIS_Target__c**.
3. Action: **Upsert**, External Id field: **External_Id__c**.
4. Paste the sheet (headers + your data rows, **without** the description row).
5. Map columns (Inspector auto-maps by API name, including the `__r.` lookup columns).
6. Run, then review the result/error columns Inspector appends.

After import, run the **Recalculate Incentive** action (or the daily batch) to populate
achievement and incentive.
