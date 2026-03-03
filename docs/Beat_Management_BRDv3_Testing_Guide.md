# Beat Management BRD v3 — QA Testing Guide
## Elite Foods Project
### Version: 1.0 | Date: 2026-03-03

---

## Pre-requisites
- System Administrator profile assigned
- Beat_Management_Admin permission set assigned
- Test users created across hierarchy (ASM → TSM → TSE → DSM/SSA)
- Test Primary Customers and Secondary Customers created
- Test beats with beat items assigned to DSMs

---

## Test Case 1: Reportee View — Today's Visit Tab

### TC-1.1: View Subordinate List
**Steps:**
1. Login as ASM (reporting manager)
2. Navigate to Today's Visit tab
3. Click "Reportee View" toggle
**Expected:** All subordinates visible with name, role, active/inactive badge

### TC-1.2: View Subordinate Beats
**Steps:**
1. From reportee view, select a subordinate (DSM)
2. Observe the beats panel
**Expected:** All ACTIVE beats of selected DSM displayed (no date restriction)

### TC-1.3: Start Visit on Subordinate Beat
**Steps:**
1. Select a subordinate's beat
2. Click "Start Visit" on an outlet
3. Complete the visit check-in flow
**Expected:** Visit created successfully, attributed to the manager's daily log

### TC-1.4: Inactive Subordinate Beats Still Visible
**Steps:**
1. Deactivate a DSM user
2. Login as ASM
3. Open Reportee View
**Expected:** DSM shown as "Inactive" but beats still visible and accessible

### TC-1.5: Cross-Hierarchy Restriction
**Steps:**
1. Login as ASM-A
2. Open Reportee View
**Expected:** Only ASM-A's subordinates visible. No users from other ASM's hierarchy.

---

## Test Case 2: Deactivate User with Beat Options

### TC-2.1: Deactivate with Beats Active
**Steps:**
1. Login as Admin
2. Go to Employee record of a DSM with active beats
3. Click "Deactivate User"
4. Select "Deactivate user with beats Active"
5. Confirm
**Expected:** User deactivated. All beats remain Active. Customer access shared to reporting manager.

### TC-2.2: Deactivate with Beats Inactive
**Steps:**
1. Login as Admin
2. Go to Employee record of a DSM with active beats
3. Click "Deactivate User"
4. Select "Deactivate user with beats Inactive"
5. Confirm
**Expected:** User deactivated. All beats + beat items set to Inactive. Customer access shared to reporting manager.

### TC-2.3: Verify Customer Access Sharing
**Steps:**
1. After TC-2.1 or TC-2.2, login as the reporting manager
2. Check if they can see the deactivated user's customers
**Expected:** Reporting manager has access to deactivated user's customers via Apex sharing

---

## Test Case 3: Beat Transfer (Not Clone)

### TC-3.1: Primary Customer Replacement — Beat ID Preserved
**Steps:**
1. Note the Beat ID of a beat under Primary Customer A
2. Perform customer replacement: Primary Customer A → Primary Customer B
3. Check the beat record
**Expected:** Same Beat ID. Primary_Customer__c updated to Customer B. No new beat record created.

### TC-3.2: Only Active Beats Transferred
**Steps:**
1. Primary Customer A has 3 active beats and 2 inactive beats
2. Perform replacement to Customer B
**Expected:** 3 active beats transferred to Customer B. 2 inactive beats remain with Customer A.

### TC-3.3: Transferred Beats Have Active Status
**Steps:**
1. Perform DB transfer from DB1 to DB2
2. Check beat status on DB2
**Expected:** All transferred beats have Active status on DB2.

### TC-3.4: Junction Beat Items Intact After Transfer
**Steps:**
1. Note beat items (outlets) under a beat before transfer
2. Perform transfer
3. Check beat items
**Expected:** All beat items (Junction_Beat__c) still linked to the same beat with same data.

---

## Test Case 4: Share Beats Button

### TC-4.1: Share Beats to Peer
**Steps:**
1. Login as Admin
2. Go to Employee record of DSM-A
3. Click "Share Beats" button
4. System shows list of users reporting to DSM-A's reporting manager
5. Select DSM-B
6. Confirm
**Expected:** DSM-B can now access DSM-A's beats.

### TC-4.2: Verify Shared Beat Access
**Steps:**
1. After TC-4.1, login as DSM-B
2. Navigate to beats
**Expected:** DSM-B can see DSM-A's shared beats.

---

## Test Case 5: Beat Owner Change Profile Restriction

### TC-5.1: Same Profile — Allowed
**Steps:**
1. Login as Admin
2. Change beat owner from DSM-A (DSM profile) to DSM-B (DSM profile)
**Expected:** Beat owner change successful.

### TC-5.2: Different Profile — Blocked
**Steps:**
1. Login as Admin
2. Try to change beat owner from DSM-A (DSM profile) to TSE-A (TSE profile)
**Expected:** Error message: "Beat owner change is only allowed between users of the same profile"

---

## Test Case 6: Beat Items Cascade Activation/Deactivation

### TC-6.1: Activate Beat → Items Activate
**Steps:**
1. Have a beat with status Inactive and 5 beat items (all inactive)
2. Change beat status to Active
**Expected:** All 5 beat items automatically become Active.

### TC-6.2: Deactivate Beat → Items Deactivate
**Steps:**
1. Have a beat with status Active and 5 beat items (all active)
2. Change beat status to Inactive
**Expected:** All 5 beat items automatically become Inactive.

---

## Test Case 7: PJP Auto-Approval

### TC-7.1: Admin Creates PJP — Auto Approved
**Steps:**
1. Login as Admin
2. Create PJP for any payroll user
**Expected:** PJP item Status__c = 'Approved' automatically.

### TC-7.2: Manager Creates PJP for Subordinate — Auto Approved
**Steps:**
1. Login as TSE (reporting manager)
2. Create PJP for subordinate DSM
**Expected:** PJP item auto-approved.

### TC-7.3: User Creates Own PJP — Normal Approval
**Steps:**
1. Login as DSM
2. Create PJP for self
**Expected:** PJP goes through normal approval process (NOT auto-approved).

---

## Regression Test Cases

### RT-1: Existing Beat Clone Still Works
**Steps:**
1. Use existing clone beat functionality
**Expected:** Clone works as before, no regression.

### RT-2: Existing Beat Owner Change Still Works
**Steps:**
1. Change beat owner between same-profile users
**Expected:** Works as before + profile validation added.

### RT-3: Existing Visit Check-in Flow Unchanged
**Steps:**
1. Login as DSM, start day, select beat, check-in to outlet
**Expected:** Entire visit flow works as before.

### RT-4: Existing Employee Replacement Flow
**Steps:**
1. Perform employee replacement (clone scenario)
**Expected:** BeatCloneBatch works as before.

---

## Sign-off Checklist
| Test Case | Tester | Date | Pass/Fail | Notes |
|-----------|--------|------|-----------|-------|
| TC-1.1 | | | | |
| TC-1.2 | | | | |
| TC-1.3 | | | | |
| TC-1.4 | | | | |
| TC-1.5 | | | | |
| TC-2.1 | | | | |
| TC-2.2 | | | | |
| TC-2.3 | | | | |
| TC-3.1 | | | | |
| TC-3.2 | | | | |
| TC-3.3 | | | | |
| TC-3.4 | | | | |
| TC-4.1 | | | | |
| TC-4.2 | | | | |
| TC-5.1 | | | | |
| TC-5.2 | | | | |
| TC-6.1 | | | | |
| TC-6.2 | | | | |
| TC-7.1 | | | | |
| TC-7.2 | | | | |
| TC-7.3 | | | | |
| RT-1 | | | | |
| RT-2 | | | | |
| RT-3 | | | | |
| RT-4 | | | | |
