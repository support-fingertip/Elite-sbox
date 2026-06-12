# Secondary Targets & PBIS — User Manual

End-to-end guide to the Secondary Targets and Performance-Based Incentive Scheme
(PBIS) module: how administrators configure it, how DSM / SSA field staff use
it day-to-day, and how managers and heads monitor their teams.

> **Module scope** — *secondary* sales by DSM / SSA staff (orders booked at
> outlets after primary distributor sales). Primary-scheme targets and reports
> are a separate, older module and are not covered here.

---

## Contents

1. [What the Module Does](#1-what-the-module-does)
2. [Key Concepts & Glossary](#2-key-concepts--glossary)
3. [Tabs at a Glance](#3-tabs-at-a-glance)
4. [Admin Manual](#4-admin-manual) — setup, slabs, batches, troubleshooting
5. [Sales User Manual (DSM / SSA)](#5-sales-user-manual-dsm--ssa)
6. [Hierarchy User Manual (TSE / ASM / RSM / Heads)](#6-hierarchy-user-manual-tse--asm--rsm--heads)
7. [Period Revisions & Lifecycle Rules](#7-period-revisions--lifecycle-rules)
8. [Frequently Asked Questions](#8-frequently-asked-questions)
9. [Appendix A — Operator Reference](#appendix-a--operator-reference)
10. [Appendix B — Field Reference](#appendix-b--field-reference)

---

## 1. What the Module Does

The module digitises three things the MIS team used to maintain in Excel:

| BRD Reference | Capability                                  | Owner               |
| ------------- | ------------------------------------------- | ------------------- |
| §3            | Secondary Targets vs Achievement engine     | Admin sets up; daily batch runs |
| §3.4          | Focus Pack masters (channel-scoped SKUs)    | Admin               |
| §5            | Monthly Performance-Based Incentive Scheme  | Admin runs monthly  |
| §4            | KPI visibility for sales staff & managers   | Everyone            |

It runs daily to compute *how much* each DSM / SSA has achieved against their
target, and runs monthly to convert those achievements into a per-criterion
incentive payout using configurable slabs.

---

## 2. Key Concepts & Glossary

| Term                     | Meaning |
| ------------------------ | ------- |
| **DSM / SSA**            | Distributor Sales Man / Senior Sales Associate — the field staff whose secondary sales are tracked. Identified in Salesforce by the **DSM** or **SSA** profile. |
| **Target Criterion**     | A reusable parameter definition (e.g. "Cumulative Secondary Revenue", "Focus Pack ECO", "Average TLSD"). Stored on `Target_Criteria__c`. Configured once by the admin. |
| **Focus Pack**           | A bundle of SKUs with a minimum qualifying quantity. Used by `FOCUS_PACK_*` criteria. Stored on `Focused_Pack__c`. |
| **Secondary Target**     | One DSM/SSA's target for **one criterion** over **one date range**. Stored on `Secondary_Target__c`, name format `STGT-0001`. Each target carries the user, criterion, optional Focus Pack, channel, target value, achievement (computed), and active flag. |
| **Achievement**          | The actual measured value, computed daily by the **Secondary Achievement Batch** from the configured criterion. |
| **Working Days**         | Days a DSM/SSA had Start Day done (from `Daily_Log__c.Day_Started_Date__c`), used as the divisor for averaging criteria (TC / PC / TLSD). |
| **Incentive Slab**       | A payout bracket on `Incentive_Slab__c`: "if Achievement % between 100 and 105, pay ₹1,000". Slabs are per criterion, per sales channel, optionally per Focus Pack, and compare either the percent or the raw value. |
| **Incentive Credit**     | One earned payout row on `Incentive_Credit__c`. Each row carries Source=`'Secondary PBIS'`, Year / Month, the matched slab, and the `Credit_Amount__c`. A DSM/SSA's monthly payout is the sum of their credit rows for the month. |
| **PBIS run**             | The monthly compute that reads each DSM/SSA's achievements and writes the matching `Incentive_Credit__c` rows. |
| **Period**               | Year + Month. All PBIS results are keyed by these two fields. |

---

## 3. Tabs at a Glance

| Tab                             | LWC                       | Audience           | Purpose |
| ------------------------------- | ------------------------- | ------------------ | ------- |
| **Target Criteria Manager**     | `tamCriteriaBuilder`      | Admin              | Define / edit reusable criteria (4-step wizard). |
| **Focused Pack**                | `focusedPackForm`         | Admin              | Create / edit Focus Pack masters. |
| **Secondary Target Manager**    | `secondaryTargetManager`  | Admin              | Create / edit `Secondary_Target__c` rows per user / criterion / period. Bulk import via CSV, export, recalc on demand, view per-target calculation breakdown. |
| **Secondary PBIS Slabs**        | `secondaryPbisSlabs`      | Admin              | Maintain payout slabs per criterion / channel / Focus Pack. Bulk add supported. |
| **Secondary PBIS Console**      | `secondaryPbisConsole`    | Admin              | Run PBIS for a selected month, view totals per user, drill into per-criterion breakdown, export CSV. |
| **Secondary KPI Dashboard**     | `secondaryKpiDashboard`   | Everyone           | Mobile-friendly dashboard. DSM/SSAs see their own; managers see team analytics + drill-in. Tab is `DefaultOn` for every profile. |

---

## 4. Admin Manual

### 4.1 Setup Order (One-Time)

Run this sequence in order. Later steps depend on the master data from earlier
steps.

1. **Create Target Criteria** — define every parameter the business wants to
   track (Revenue, TC, PC, UBO/ECO, TLSD, FP Revenue, FP ECO, …).
2. **Create Focus Packs** — the SKU bundles + minimum qualifying quantity used
   by `FOCUS_PACK_*` criteria.
3. **Create Secondary Targets** — assign each DSM/SSA the criteria they will be
   measured on with their target value and active date range. Use the CSV
   importer for bulk uploads.
4. **Configure Incentive Slabs** — for each criterion (and channel / Focus
   Pack where relevant), set the payout brackets.
5. **Schedule the daily achievement batch** — so achievements stay current.
6. **Schedule the monthly PBIS batch** *or* run on demand from the PBIS Console.

### 4.2 Defining a Target Criterion

Open **Target Criteria Manager** → **New Criterion**. The wizard has four
steps:

| Step | What you set |
| ---- | ------------ |
| **1. Basics**     | Name, Active flag. *(The Incentive section that lived on this step in early builds was removed.)* |
| **2. Calculation** | Operator (see [Appendix A](#appendix-a--operator-reference)) and the operator-specific fields. The fields shown adapt to the operator so you never see irrelevant inputs. |
| **3. Source**     | Object, User Field, Date Field, optional Filters / Filter Logic, optional Secondary Source Objects (UI builder — no JSON typing). |
| **4. Preview**    | Sample run for a date range so you can sanity-check the configuration before saving. |

**Operator quick-pick**

| Sales parameter (BRD)                | Operator              | Distinct / Numerator / Denominator |
| ------------------------------------ | --------------------- | ---------------------------------- |
| Cumulative Secondary Revenue         | `SUM`                 | —                                  |
| UBO / ECO                            | `COUNT_DISTINCT`      | Distinct = outlet field            |
| Total Calls (TC)                     | `DAILY_UNIQUE_AVG`    | Distinct = outlet; add `Secondary Source Objects` to union order + visit-form sources |
| Productive Calls (PC)                | `DAILY_UNIQUE_AVG`    | Distinct = outlet, orders only     |
| Average TLSD (lines per order / day) | `DAILY_RATIO_AVG`     | Numerator = line items, Denominator = orders |
| Focus Pack Revenue                   | `FOCUS_PACK_REVENUE`  | Focus Pack set on each target      |
| Focus Pack ECO                       | `FOCUS_PACK_ECO`      | Focus Pack set on each target      |

> **`Use Attendance Divisor`** — tick this on daily-averaging criteria so the
> divisor is **working days** (BRD §3.3.1) instead of calendar days.

### 4.3 Creating Focus Packs

Open **Focused Pack** → **New**. Set:

- **Name** — descriptive (e.g. "Diwali Focus Pack — CPD").
- **Sales Channel** — the channel this pack applies to (drives the SKU picker).
- **Minimum Qualifying Quantity** — total units across the pack SKUs needed in
  *one order* to count as Focus Pack ECO (BRD §3.4.5).
- **Items** — pick SKUs from the channel-filtered list, each with a minimum quantity.

### 4.4 Creating Secondary Targets

**Open Secondary Target Manager.**

#### Manual creation
1. Click **New**.
2. Pick the **User** (DSM / SSA), the **Target Criterion**, the **Focus Pack**
   (only for `FOCUS_PACK_*` criteria), the **Sales Channel**, **Year**, the
   **Start Date** and **End Date**, and the **Target Value**.
3. Save.

The system enforces:
- **End Date ≥ Start Date** always.
- **End Date ≥ today** on create — but Start Date *can* be in the past so
  quarterly / annual targets created mid-period still work.
- **No duplicate active overlapping target** for the same `(User, Criterion,
  Focus Pack)` combination. If a duplicate is attempted the save is blocked.

#### Bulk import via CSV
1. Click **Download CSV Template** for a header row with a sample line.
2. Fill the spreadsheet. Required columns:
   - `Target Name` *(only used when updating; blank for new targets)*
   - `User Employee Code` — maps to `User.Employee_Code__c`.
   - `Criteria Name`
   - `Focus Pack Name` *(blank for non-focus-pack criteria)*
   - `Sales Channel`
   - `Year`
   - `Start Date (YYYY-MM-DD)` and `End Date (YYYY-MM-DD)`
   - `Target Value`
   - `Is Active` (`true` / `false`)
3. Click **Import CSV** and pick the file. The importer:
   - Strips BOM, auto-detects `,` / `;` / tab delimiter.
   - Matches headers case-insensitively.
   - Resolves users by `Employee_Code__c`, criteria & packs by Name.
   - Rejects the whole upload on validation errors and shows which rows failed.

#### Filters & list view
The table has Channel, Criteria, **User** and Active filters. Sortable columns
include the new **Start Date** and **End Date** so you can scan periods at a
glance.

#### Per-row actions
- **Recalculate** — re-runs the calculation engine *just for this target* and
  refreshes the row.
- **View Calculation** — opens a modal showing every input the engine used,
  per-day math (where applicable), and the final formula. Use this when a
  user disputes their achievement.

#### Export
**Export** writes the currently filtered rows to a CSV (with UTF-8 BOM so
Excel opens it cleanly), including target value, achievement value, %, pending,
working days, active flag and last-updated timestamp.

### 4.5 Recalculating Achievement

Achievement is normally refreshed by the **daily batch**. You can also:

- **Per target** — click *Recalculate* on a row (see above).
- **All active targets** — click **Run Daily Recalc** at the top of the Target
  Manager. Internally this enqueues the `SecondaryAchievementBatch` for active
  rows whose date range includes today (BRD §3.1.1).

### 4.6 Configuring Incentive Slabs

Open **Secondary PBIS Slabs** → **New Slab**. Slab fields:

| Field                | Notes |
| -------------------- | ----- |
| **Target Criteria**  | The criterion this slab pays out for. Required. |
| **Sales Channel**    | Slabs are channel-scoped (different states / channels often pay differently). |
| **Focused Pack**     | Optional. When set, this slab wins over a generic channel-default slab for the same Focus Pack (pack-specific overrides). |
| **Compare On**       | `Percent` (compare against Achievement %) or `Value` (compare against Achievement Value). |
| **Achievement From / To** | Inclusive bracket. Leave **To** blank for "unbounded upwards". |
| **Incentive Amount** | Flat payout when this slab matches. |
| **Active**           | Inactive slabs are ignored. |

**Bulk Add Slabs** lets you enter many slabs at once for one criterion +
channel (one row per bracket, with a Clone Row helper).

#### Matching rules (informational)
For each `(User, Criterion, Focus Pack)` target row the engine:

1. Filters slabs to the user's channel and the target's criterion. Pack-specific
   slabs are preferred when available.
2. Picks the value to compare based on `Compare On`.
3. Selects all qualifying brackets (`From ≤ value` and `To is null OR value ≤ To`).
4. Tie-breaks on highest `Achievement_From__c`, then highest `Incentive_Amount__c`.
5. Writes one `Incentive_Credit__c` row carrying the criterion, focus pack,
   matched slab, and snapshot achievement.

### 4.7 Running PBIS Monthly

Open **Secondary PBIS Console**.

1. Pick **Year** and **Month** (defaults to the current month).
2. Click **Run PBIS for this Month**.
   - The button is **asynchronous** (queueable), so it returns immediately
     with a toast. The screen auto-refreshes after ~5 s once the job commits.
3. Each run is **idempotent**: prior `Incentive_Credit__c` rows for that month
   are deleted before the fresh rows are inserted — so you can re-run safely
   after fixing a slab or a target.

**What you see after a run**

| Section              | Description |
| -------------------- | ----------- |
| Grand Total          | Sum of all PBIS payouts written for the month. |
| Per-user totals      | One row per user × channel with monthly total and line count. Click the row action to **View breakdown**. |
| Breakdown            | Per-criterion lines for the picked user — Target name, Criterion, Focus Pack, Compare On, Achievement, Slab range, Amount. |
| Duplicates skipped   | If two active overlapping targets share the same `(user, criterion, focus pack)` key, the engine deduplicates (kept the better one, skipped the rest). The skipped rows + their winners are listed so you can clean them up — deactivate the duplicates and re-run. |

**Export** → downloads every PBIS row for the month as CSV (Executive, Channel,
Year, Month, Target, Criterion, Operator, Focus Pack, Compare On, Achievement
Value, Achievement %, Slab From / To, Incentive Amount, Computed At).

### 4.8 Scheduling the Batches

In Setup → Apex Classes → **Schedule Apex** (or via anonymous Apex):

| Job                         | Class                            | Suggested cron |
| --------------------------- | -------------------------------- | -------------- |
| Daily achievement refresh   | `SecondaryAchievementScheduler`  | every day 01:30 |
| Monthly PBIS                | `SecondaryPBISScheduler`         | 02:00 on the 1st of every month — computes the prior month |

The monthly scheduler reads the **prior calendar month** automatically; the
PBIS Console "Run" button always uses the explicit Year/Month you pick.

### 4.9 Operational Troubleshooting

| Symptom                                                   | What to do |
| --------------------------------------------------------- | ---------- |
| Target shows `Achievement = 0` after running the batch    | Open *View Calculation* on the row — the modal lists the raw inputs the engine saw. Most often a Date Field or User Field on the criterion is misconfigured, the user has no `Daily_Log__c` rows for the period, or the filter excludes the matching orders. |
| Achievement % suddenly jumps                              | Targets may have been edited mid-period. Use the per-row *Recalculate* to refresh just that row. |
| Two targets for the same user & criterion                 | The PBIS engine will keep the better one and list the other in *Duplicates skipped* on the Console. Deactivate the loser (uncheck `Is_Active__c`) to clean up. |
| Need to re-run PBIS after a slab fix                      | Just click **Run PBIS for this Month** again — the run is idempotent. |
| CSV upload rejected with header / encoding errors         | The importer auto-detects `,` / `;` / tab and strips BOM; if it still fails, re-save the file as **CSV (UTF-8)** from Excel. |
| User says "I don't see the KPI Dashboard tab"             | Tab access was already pushed `DefaultOn` for all 49 profiles. If a custom profile is missing it, add a `tabVisibilities` entry for `Secondary_KPI_Dashboard`. |
| Dashboard shows duplicate rows for users sharing a role   | Fixed in current build — direct subordinates are now grouped by role, with a `(+N more)` label when several users share one role. |

---

## 5. Sales User Manual (DSM / SSA)

DSM and SSA users have **read-only** access to the dashboard — they don't edit
targets or slabs. The whole experience is on the **Secondary KPI Dashboard**
tab, which is mobile-optimised because field staff are on phones.

### 5.1 Opening the Dashboard

- **Desktop** — App Launcher → **Secondary KPI Dashboard**.
- **Mobile** — bottom-nav More menu → **Secondary KPI Dashboard**.

### 5.2 What You See (Personal View)

Because you are a DSM / SSA, the dashboard is locked to your own data — there
is no user picker.

#### Header
- Your name, your role, your Employee Code, your Sales Channel.
- The period being shown (defaults to the current calendar month).

#### Hero tiles
- **Active Targets** — how many secondary targets you have running this period.
- **Total Target** — sum of your target values across criteria.
- **Achievement** — sum of what you've achieved so far, plus your overall **Ach %** with a coloured bar:
  - 🟢 ≥ 100 % (on or above target)
  - 🟠 80 – 99 % (close but pushing)
  - 🔴 < 80 % (behind)
- **PBIS Incentive** — what you've earned for the period, plus the count of credit lines.

#### Active Secondary Targets
A list of every active target you have. On mobile each target is a card; on
desktop it's a table. Each row shows:

| Field         | What it means |
| ------------- | ------------- |
| Criterion / Focus Pack / Channel | What this target is measuring. |
| Target        | The number you have to hit. |
| Achievement   | What you've achieved so far. |
| Ach %         | Percent, with the same green / amber / red bucket. |
| Pending       | Target − Achievement (how much further to go). |
| Working Days  | Working days used in the divisor (for averaging criteria). |
| Incentive     | The PBIS amount you've earned on this specific criterion this month. |

### 5.3 Changing the Period

Use **Year** and **Month** at the top. The dashboard refreshes immediately.

### 5.4 Things to Know

- **Achievement updates daily.** If the latest order isn't reflected yet, wait
  for the next day's batch — or ask your manager to trigger a per-target
  recalculation.
- **Working days affect averages.** Days you didn't start your day in the app
  (no `Daily_Log__c.Day_Started_Date__c`) are excluded from the divisor for TC
  / PC / TLSD-style criteria. Approved leave days are also excluded.
- **Incentives appear after the monthly PBIS run.** The PBIS run typically
  happens shortly after month-end. Until then, the Incentive tile shows ₹0.
- You **cannot edit** targets or slabs. If a target looks wrong, escalate to
  your TSE / ASM or the MIS team.

---

## 6. Hierarchy User Manual (TSE / ASM / RSM / Heads)

Managers and heads use the **Secondary KPI Dashboard** to monitor every DSM /
SSA in their reporting hierarchy. The dashboard has two modes:

- **Team mode** (default) — analytics across your whole team.
- **Personal mode** — drill into one DSM / SSA.

The **DSM / SSA picker** at the top switches between them.

### 6.1 Opening the Dashboard

App Launcher → **Secondary KPI Dashboard**. Works the same on mobile.

### 6.2 The Picker (your scope)

The "View" combobox lists:

- **All my DSM / SSAs** (default) — team mode.
- Each individual DSM / SSA in your role-hierarchy downline, labelled
  `Name · EMP001 (DSM)`.

You only see DSM / SSAs that report to you (recursively, through the Salesforce
role hierarchy). If you have none, the dashboard shows a friendly empty state
explaining how to ask the admin to assign DSM / SSAs to your branch of the
hierarchy.

### 6.3 Team Mode

#### Hero tiles
- **Targeted Users** — number of DSM / SSAs in your team who actually carry at
  least one active secondary target this period (not raw headcount — that was
  misleading; this number matches the rest of the analytics on this page).
- **Active Targets** — total across your team.
- **Total Target** — sum.
- **Achievement** — sum + overall Ach % + coloured bar.
- **PBIS Incentive** — sum of payouts earned by your team this period.

#### My DSM / SSAs
A table of every team member with secondary activity, sorted by Ach %
descending. Columns: Name, Role, Channel, Targets, Target, Achievement, Ach %,
Incentive.

- **Drill in** — pick the *View this user* row action (desktop) or tap the card
  (mobile). The whole dashboard switches to **Personal mode** for that user.
- A **Back to team** button appears in personal mode to return.

#### Top Performers
Top 5 DSM / SSAs by Ach %, requiring a non-zero target so empty users don't
dominate. Useful for monthly recognition.

#### Needs Attention
Bottom 5 by Ach %, same filter. Useful for proactive coaching.

#### Achievement by Sales Channel
One bar per channel (CPD / TN / KN / etc.) showing the channel's overall
Ach %, plus the achievement and target totals and how many users contributed.

#### Achievement by Criterion
One bar per criterion (Revenue, TC, PC, FP ECO, …) — the same view from the
criterion's perspective. Use it to spot which BRD parameters the team is
under-performing on.

### 6.4 Personal Mode (picking one DSM / SSA)

When you select a specific user from the picker — or drill in from the team
table — the dashboard becomes the same view a DSM / SSA sees:

- Hero with that user's totals.
- Per-target list with Criterion, Focus Pack, Channel, Target, Achievement,
  Pending, Incentive.

Use the **Back to team** button (top right) to return to team mode.

### 6.5 Things to Know

- The picker filters to **DSM / SSA profiles only** — finance, distributor,
  partner-community users in your downline don't appear, and they don't
  contaminate the aggregates.
- A manager can only view DSM / SSAs **inside** their hierarchy. If a user id
  outside your hierarchy is somehow passed (URL hack, etc.), the server falls
  back to team mode for your own scope — no data leak.
- **DSM / SSAs can't see this view.** When a DSM / SSA logs in, the picker is
  hidden and the dashboard is locked to themselves on the server, regardless
  of any client-side state.
- Period filter (Year + Month) applies to the *whole* dashboard.

---

## 7. Period Revisions & Lifecycle Rules

When a target needs to change mid-period (BRD §3.1.1 / §6), **never edit an
active row**. The correct flow:

1. Open the existing `Secondary_Target__c` row.
2. **Deactivate** it (`Is_Active__c = false`) and set `End_Date__c` to the
   close-out date.
3. **Create a new row** for the new effective period with the revised target.

The engine only reads `Is_Active__c` + the date range, so the closed row is
ignored from then on while remaining as an audit record. The achievement
computed against it is preserved.

A duplicate guard at save time blocks creating a *new* active row that
overlaps an existing active row for the same `(User, Criterion, Focus Pack)`
combination. If two slip through (e.g. via legacy data), the PBIS engine's
deduplication safety net keeps the better-achievement row and surfaces the
losers on the Console's "Duplicates skipped" panel.

---

## 8. Frequently Asked Questions

**Q. A DSM achieved 150 % — does that mean they hit 1.5 × target?**
Yes. There is no cap on achievement %. The corresponding slab payout is
whatever the highest qualifying bracket pays.

**Q. What if a target has Target Value = 0?**
Achievement % is computed as 0 % in that case (we never divide by zero). The
target is still tracked in the per-target list, but it won't contribute
meaningfully to channel / criterion bars.

**Q. Can the same DSM have two Focus Pack ECO targets for two different packs
in the same month?**
Yes. The active-duplicate guard keys on `(User, Criterion, Focus Pack)`, so
two different Focus Packs are perfectly valid.

**Q. Why are PBIS payouts shown per criterion instead of one total per user?**
Because each criterion has its own slab table and its own payout. The
per-criterion rows let MIS / payroll explain a DSM's monthly payout line by
line. The dashboard sums them into the headline number you see at the top.

**Q. Will achievement update in real time?**
No. It's computed by a daily batch (and an on-demand recalc button). Real-time
recompute on every order write would be too expensive for 250 users × 7
criteria. Achievement lags the latest order by up to one batch cycle.

**Q. How does the engine know which orders are "secondary"?**
Order-based criteria filter on `Order_Type__c` (or `Customer_Order_Type__c`
for focus-pack criteria — confirm the exact value in the criterion's Filters
step). Make sure the secondary order pipeline writes the agreed value
consistently.

**Q. What happens if I deactivate a slab that's already paid out?**
Past `Incentive_Credit__c` rows are untouched. Next month's run won't use the
deactivated slab.

**Q. The "Back to team" button is missing.**
You either (a) are not in personal mode, or (b) are a DSM / SSA — DSMs are
locked to their personal view by design.

---

## Appendix A — Operator Reference

The operator on `Target_Criteria__c.Operator__c` controls how the engine
computes achievement. The Criteria Manager wizard adapts to whichever operator
you pick.

| Operator               | BRD Parameter                          | Required fields on the criterion                       |
| ---------------------- | -------------------------------------- | ------------------------------------------------------ |
| `SUM`                  | Cumulative Secondary Revenue           | Object, Field (the numeric column), Date Field, User Field, optional Filters |
| `COUNT`                | (any plain count)                      | Object, Date Field, User Field, Filters                 |
| `COUNT_DISTINCT`       | UBO / ECO                              | + Distinct Field (the outlet column, e.g. `Account__c` or `Order__r.Account__c`) |
| `DAILY_UNIQUE_AVG`     | TC, PC                                 | + Distinct Field; tick **Use Attendance Divisor**; for TC also fill **Secondary Source Objects** (UI builder) to union order + visit-form sources |
| `DAILY_RATIO_AVG`      | Average TLSD                           | Numerator Field (line items), Denominator Field (orders); attendance divisor on |
| `FOCUS_PACK_REVENUE`   | Focus Pack Revenue                     | The Focus Pack is set on each `Secondary_Target__c` row; criterion stays "stub"-style. |
| `FOCUS_PACK_ECO`       | Focus Pack ECO                         | Same. ECO is per-order qualifying — `SUM(pack-SKU Quantity) ≥ Focus Pack.Min Qty` within one order (BRD §3.4.5). |

**Working-day divisor** — controlled by `Use_Attendance_Divisor__c`. Working
days = dates in the period with `Daily_Log__c.Day_Started_Date__c` for that
user. Approved full-day leaves with no Start Day are excluded; telephonic-only
days are excluded from the divisor too (though their orders still contribute
to the numerator).

---

## Appendix B — Field Reference

Compact field map for admins reading data via SOQL / reports.

### Secondary_Target__c

| API Name                 | Type    | Notes |
| ------------------------ | ------- | ----- |
| `Name`                   | Auto    | `STGT-0000` |
| `User__c`                | Lookup → User | The DSM / SSA |
| `User_Name__c`           | Text    | Snapshot for display |
| `Sales_Channel__c`       | Picklist | Channel value-set |
| `Year__c`                | Number  | |
| `Start_Date__c` / `End_Date__c` | Date | Effective period |
| `Target_Criteria__c`     | Lookup  | The criterion |
| `Target_Value__c`        | Number  | The number to hit |
| `Achievement_Value__c`   | Number  | Engine-written |
| `Achievement_Percent__c` | Number  | Engine-written |
| `Pending_Target__c`      | Number  | Target − Achievement |
| `Working_Days__c`        | Number  | Divisor used (audit) |
| `Daily_Achievement__c`   | Number  | Today's increment |
| `Focused_Pack__c`        | Lookup  | Required for `FOCUS_PACK_*` criteria |
| `Is_Active__c`           | Checkbox | The lifecycle gate |
| `Last_Updated__c`        | DateTime | Last batch / recalc |

### Incentive_Slab__c (Secondary additions)

| API Name              | Notes |
| --------------------- | ----- |
| `Target_Criteria__c`  | Identifies a Secondary slab (must be set) |
| `Sales_Channel__c`    | Channel filter |
| `Focused_Pack__c`     | Optional pack override |
| `Compare_On__c`       | `Percent` or `Value` |
| `Achievement_From__c` / `Achievement_To__c` | Inclusive bracket |
| `Incentive_Amount__c` | Flat payout |
| `Active__c`           | Inactive ⇒ ignored |

### Incentive_Credit__c (Secondary additions)

| API Name               | Notes |
| ---------------------- | ----- |
| `Source__c`            | Always `Secondary PBIS` for this module |
| `Executive__c`         | User who earned it |
| `Year__c` / `Month__c` | Natural key for monthly idempotency |
| `Sales_Channel__c`     | |
| `Target_Criteria__c`   | The criterion that paid |
| `Focused_Pack__c`      | Set for pack criteria |
| `Matched_Slab__c`      | The slab that decided the amount |
| `Secondary_Target__c`  | The source achievement row (audit) |
| `Achievement_Value__c` / `Achievement_Percent__c` | Snapshot at compute time |
| `Compare_On__c`        | Snapshot — what the slab compared |
| `Credit_Amount__c`     | The paid amount |
| `Computed_At__c`       | When the row was written |

---

*This manual reflects the module as of the current build. UI labels and
screenshots are based on the live LWCs in `force-app/main/default/lwc/`.
Open a Jira ticket against the Sales / MIS squad for substantive corrections.*
