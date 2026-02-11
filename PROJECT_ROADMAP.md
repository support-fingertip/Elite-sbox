# Elite-sbox: Salesforce Application (SFA) - Project Roadmap

## 1. Executive Summary

**Project Type:** Salesforce DX (SFDX) CI/CD Framework & Project Template Generator
**Repository:** Elite-sbox
**Current State:** Infrastructure-only (no business logic yet deployed)
**API Version:** 59.0 (configurable)
**Tech Stack:** GitHub Actions, Salesforce CLI (`sf`), SFDX Source Format

This repository serves as an **automation backbone** for Salesforce development. It provides three core GitHub Actions workflows that handle project scaffolding, delta deployments, and metadata retrieval. No Apex business logic, custom objects, or LWC application components exist yet -- the repo is a launchpad ready to support a full SFA build.

---

## 2. Current Architecture Analysis

### 2.1 Repository Structure (As-Is)

```
Elite-sbox/
  .github/
    workflows/
      skeleton.yml      # Project skeleton generator (19 KB, most complex)
      main.yml          # Delta deployment pipeline (1.7 KB)
      retrieve.yml      # Metadata retrieval pipeline (1.1 KB)
  README.md             # Minimal placeholder
```

### 2.2 Module Breakdown: Existing Workflows

#### Module A: Project Skeleton Generator (`skeleton.yml`)

| Attribute        | Detail |
|------------------|--------|
| **Trigger**      | `workflow_dispatch` (manual) |
| **Inputs**       | `branch_name`, `project_name`, `api_version` |
| **Steps (14)**   | Checkout -> Git config -> Branch create/switch -> Dir structure -> sfdx-project.json -> .forceignore -> .gitignore -> VS Code settings -> Sample Apex -> Sample LWC -> package.xml -> README -> Placeholders -> Commit/Push |

**Functions Performed:**
1. Creates 17 directories under `force-app/main/default/` (classes, triggers, lwc, aura, objects, layouts, flows, permissionsets, profiles, staticresources, tabs, pages, components, email, queues, reports, dashboards)
2. Creates utility dirs: `scripts/apex/`, `config/`, `.vscode/`
3. Generates `sfdx-project.json` with configurable namespace, login URL, API version
4. Generates `.forceignore` excluding admin profiles, jsconfig, eslintrc, app menus, object translations, connected apps
5. Generates `.gitignore` for SF-specific artifacts (.sf/, .sfdx/, auth files, deployment artifacts)
6. Sets up VS Code with Salesforce extension pack recommendations
7. Creates sample `HelloWorld.cls` (with sharing, static method, null handling)
8. Creates sample `HelloWorldTest.cls` (2 assertions, tests null and value path)
9. Creates sample `helloWorld` LWC (lightning-card, lightning-input, reactive `@track` property)
10. Generates `manifest/package.xml` covering 21 metadata types
11. Auto-commits and pushes to specified branch

**Metadata Types in package.xml:**
ApexClass, ApexTrigger, LightningComponentBundle, AuraDefinitionBundle, CustomObject, Layout, Flow, PermissionSet, Profile, StaticResource, CustomTab, ApexPage, ApexComponent, EmailTemplate, Queue, Report, Dashboard, CustomField, ValidationRule, WorkflowRule, CustomMetadata

#### Module B: Delta Deployment Pipeline (`main.yml`)

| Attribute        | Detail |
|------------------|--------|
| **Trigger**      | `push` to `main` branch |
| **Auth Method**  | SFDX Auth URL via `secrets.SALESFORCE_AUTH_URL` |
| **Target Org**   | `deployment-org` alias |

**Functions Performed:**
1. Installs Salesforce CLI globally via npm
2. Authenticates using SFDX URL file method
3. Computes delta: compares `github.event.before` commit with current `github.sha`
4. Filters changed files to only `force-app/` directory
5. Falls back to `HEAD~1` diff if previous commit SHA is unavailable
6. Deploys only changed files using `sf project deploy start --source-dir`
7. Skips deployment if no force-app changes detected
8. 30-minute wait timeout on deployment

**Key Design Decisions:**
- File-level granularity (not component-level) for delta detection
- No test execution during deployment (no `--test-level` flag)
- No validation-only mode -- deploys directly

#### Module C: Metadata Retrieval Pipeline (`retrieve.yml`)

| Attribute        | Detail |
|------------------|--------|
| **Trigger**      | `workflow_dispatch` (manual) |
| **Auth Method**  | Same SFDX Auth URL pattern |
| **Commit Author**| `GitHub Actions <actions@github.com>` |

**Functions Performed:**
1. Installs Salesforce CLI
2. Authenticates to deployment org
3. Retrieves metadata using `manifest/package.xml` as manifest
4. Cleans up auth file (`rm -f authfile.txt`)
5. Auto-commits retrieved changes with `[skip ci]` tag to prevent deployment loop
6. Pushes changes back to current branch

---

## 3. Gap Analysis & Risk Assessment

### 3.1 Current Gaps

| # | Gap | Severity | Impact |
|---|-----|----------|--------|
| 1 | No test execution in deployment pipeline | **HIGH** | Code deploys without validation; production bugs possible |
| 2 | No validation-only (check-only) deployment | **HIGH** | No PR-level quality gate before merge |
| 3 | Delta deploy passes file list to `--source-dir` directly | **MEDIUM** | Breaks if filenames contain spaces or special characters; also `--source-dir` expects directories, not individual files |
| 4 | No branch protection or environment gating | **MEDIUM** | Any push to main triggers immediate deployment |
| 5 | `authfile.txt` not cleaned up in `main.yml` | **LOW** | Auth URL persists in runner workspace (mitigated by ephemeral runners) |
| 6 | `retrieve.yml` uses `actions/checkout@v3` while `skeleton.yml` uses `v4` | **LOW** | Version inconsistency; v3 is outdated |
| 7 | No code scanning, PMD, or ESLint integration | **MEDIUM** | No static analysis for Apex or LWC code quality |
| 8 | No scratch org or sandbox strategy | **HIGH** | Developer isolation and testing environments undefined |
| 9 | Sample LWC uses deprecated `@track` decorator | **LOW** | `@track` is unnecessary since LWC v1.5 for reactive properties |
| 10 | No error handling or notifications on workflow failure | **MEDIUM** | Team has no visibility into broken deployments |

### 3.2 Security Observations

- Auth URL stored as GitHub secret (correct practice)
- Auth file created on disk during workflow execution (acceptable for ephemeral runners)
- `retrieve.yml` properly cleans up auth file; `main.yml` does not
- No IP restrictions or org-level deploy controls mentioned
- `skeleton.yml` uses `secrets.GITHUB_TOKEN` for push (standard, scoped correctly)

---

## 4. Detailed Project Roadmap

### Phase 1: Foundation Hardening (DevOps & CI/CD)

**Goal:** Make the existing pipelines production-grade before building any business logic.

#### 1.1 Fix Delta Deployment Pipeline

| Task | Description | Files |
|------|-------------|-------|
| 1.1.1 | Replace file-level `--source-dir` with proper SFDX delta plugin (`sfdx-git-delta` / `sgd`) | `.github/workflows/main.yml` |
| 1.1.2 | Add `--test-level RunLocalTests` to deploy command | `.github/workflows/main.yml` |
| 1.1.3 | Add auth file cleanup step after deployment | `.github/workflows/main.yml` |
| 1.1.4 | Upgrade `actions/checkout` to v4 across all workflows | `main.yml`, `retrieve.yml` |
| 1.1.5 | Add deployment failure notification (Slack/Email/Teams webhook) | `.github/workflows/main.yml` |

#### 1.2 Add Validation Pipeline (PR Quality Gate)

| Task | Description | Files |
|------|-------------|-------|
| 1.2.1 | Create `validate.yml` workflow triggered on `pull_request` to `main` | `.github/workflows/validate.yml` (new) |
| 1.2.2 | Run `sf project deploy start --dry-run` (check-only deployment) | Same |
| 1.2.3 | Run `sf apex run test --test-level RunLocalTests` | Same |
| 1.2.4 | Integrate Apex PMD static analysis (`pmd-github-action`) | Same |
| 1.2.5 | Add ESLint for LWC JavaScript linting | Same |
| 1.2.6 | Enforce branch protection: require PR, passing checks, and review | GitHub repo settings |

#### 1.3 Environment Strategy

| Task | Description |
|------|-------------|
| 1.3.1 | Define org strategy: Scratch Orgs for dev, Sandboxes for UAT, Production for release |
| 1.3.2 | Create `project-scratch-def.json` with required features/settings |
| 1.3.3 | Add scratch org creation workflow for developer onboarding |
| 1.3.4 | Set up named environment secrets per org tier (DEV, UAT, PROD) |
| 1.3.5 | Implement environment-specific deployment workflows with approval gates |

---

### Phase 2: Data Model & Core Objects

**Goal:** Build the foundational Salesforce data architecture for SFA.

#### 2.1 Account Management Module

| Component | Type | Description |
|-----------|------|-------------|
| `Account` (standard) | CustomField additions | Industry vertical, Account Tier (Gold/Silver/Bronze), Annual Revenue Band, Territory Code |
| `Account_Scoring__c` | Custom Object | Calculated account health score, engagement metrics, risk flags |
| `AccountTrigger` | Apex Trigger | Before insert/update: validate territory assignment, normalize industry values |
| `AccountTriggerHandler` | Apex Class | Trigger handler following single-trigger-per-object pattern |
| `AccountService` | Apex Class | Business logic: scoring calculation, territory assignment, duplicate detection |
| `AccountServiceTest` | Apex Test Class | Minimum 90% coverage, bulk test (200+ records), negative tests |
| `AccountSelector` | Apex Class | SOQL queries with field-level security enforcement |
| Account Page Layout | Layout | Optimized layout with key fields, related lists, path component |
| Account Record Types | RecordType | B2B Customer, B2C Customer, Partner, Prospect |

#### 2.2 Contact Management Module

| Component | Type | Description |
|-----------|------|-------------|
| `Contact` (standard) | CustomField additions | Preferred Communication Channel, Contact Role, Decision Maker flag, Last Engagement Date |
| `ContactTrigger` | Apex Trigger | After insert: auto-create contact role on opportunity, sync to marketing |
| `ContactTriggerHandler` | Apex Class | Handler with recursion prevention |
| `ContactService` | Apex Class | Duplicate matching, merge logic, related record updates |
| `contactCard` | LWC | Enhanced contact display with quick actions and communication buttons |
| Contact Validation Rules | ValidationRule | Email format, phone format, required fields by record type |

#### 2.3 Product & Price Book Module

| Component | Type | Description |
|-----------|------|-------------|
| `Product2` (standard) | CustomField additions | Product Line, SKU, Availability Status, Minimum Order Quantity |
| `PricebookEntry` (standard) | CustomField additions | Discount Tier, Volume Pricing Flag |
| `Product_Bundle__c` | Custom Object | Junction object linking products into bundles with quantity/discount rules |
| `ProductService` | Apex Class | Bundle pricing calculation, availability checks, compatibility validation |
| `productCatalog` | LWC | Searchable/filterable product browser with add-to-opportunity action |
| `productConfigurator` | LWC | CPQ-lite: bundle builder with real-time pricing |

#### 2.4 Custom Metadata & Settings

| Component | Type | Description |
|-----------|------|-------------|
| `App_Setting__mdt` | CustomMetadata | Application configuration (feature flags, thresholds, integration endpoints) |
| `Territory_Config__mdt` | CustomMetadata | Territory-to-region mapping, assignment rules |
| `Scoring_Weight__mdt` | CustomMetadata | Configurable weights for account/lead scoring algorithms |
| `Integration_Endpoint__mdt` | CustomMetadata | External system URLs, API versions, timeouts (deployable, not env-specific) |

---

### Phase 3: Sales Process Automation

**Goal:** Implement the core opportunity-to-close sales pipeline.

#### 3.1 Opportunity Management Module

| Component | Type | Description |
|-----------|------|-------------|
| `Opportunity` (standard) | CustomField additions | Win Probability (manual override), Competitor__c (lookup), Loss Reason Category, Forecast Category Override |
| `OpportunityTrigger` | Apex Trigger | Before update: stage validation, auto-close date adjustment; After update: notification dispatch, forecast recalculation |
| `OpportunityTriggerHandler` | Apex Class | Stage-transition logic, field dependency enforcement |
| `OpportunityService` | Apex Class | Pipeline analytics, forecast aggregation, stage duration tracking |
| `OpportunitySelector` | Apex Class | Optimized SOQL for pipeline views, forecast rollups |
| `opportunityKanban` | LWC | Drag-and-drop pipeline board with stage-based columns |
| `opportunityTimeline` | LWC | Visual timeline of stage progression with duration per stage |
| Opportunity Validation Rules | ValidationRule | Close Date not in past, Amount required at Negotiation stage, Competitor required at Closed Lost |
| Sales Process | Flow | Guided selling path with required fields per stage |
| `Opportunity_Approval` | Flow (Approval) | Multi-level approval: Manager -> VP -> C-level based on deal size thresholds |

#### 3.2 Quote & Proposal Module

| Component | Type | Description |
|-----------|------|-------------|
| `Quote` (standard) | CustomField additions | Discount Authorization Level, Valid Until auto-calculation, Terms Template |
| `Quote_Line_Item__c` | Custom Object | Enhanced line items with bundle support, volume discounting, term-based pricing |
| `QuoteService` | Apex Class | Quote generation, PDF creation, discount validation against approval matrix |
| `QuotePDFController` | Apex Class | VF page controller for branded PDF quote generation |
| `QuoteTemplate` | Visualforce Page | Branded quote PDF template with company logo, terms, line items |
| `quoteBuilder` | LWC | Interactive quote line editor with real-time totals and discount warnings |

#### 3.3 Activity & Engagement Tracking Module

| Component | Type | Description |
|-----------|------|-------------|
| `Task` (standard) | CustomField additions | Activity Type (Call/Email/Meeting/Demo), Outcome, Next Step |
| `Event` (standard) | CustomField additions | Meeting Type, External Attendees Count, Follow-up Required |
| `Engagement_Score__c` | Custom Object | Rolling engagement metrics per Account/Contact |
| `ActivityTrigger` | Apex Trigger | After insert: update engagement score, check SLA compliance |
| `ActivityService` | Apex Class | Engagement score calculation, activity gap detection, rep productivity metrics |
| `activityTimeline` | LWC | Unified activity feed across tasks, events, emails, calls |
| `activityLogger` | LWC | Quick-log component for rapid activity capture from any record page |

---

### Phase 4: Lead Management & Marketing Alignment

**Goal:** Build lead capture, qualification, and conversion pipeline.

#### 4.1 Lead Management Module

| Component | Type | Description |
|-----------|------|-------------|
| `Lead` (standard) | CustomField additions | Lead Source Detail, Lead Score (formula), Qualification Status, SLA Deadline |
| `LeadTrigger` | Apex Trigger | Before insert: auto-assign territory, deduplicate; After insert: start SLA clock |
| `LeadTriggerHandler` | Apex Class | Assignment logic, duplicate detection, score calculation |
| `LeadService` | Apex Class | Scoring algorithm (behavioral + demographic), routing rules, conversion prep |
| `LeadSelector` | Apex Class | Queries for lead queues, round-robin, territory-based views |
| `Lead_Assignment` | Flow | Auto-assignment: round-robin within territory, capacity-aware |
| `Lead_Nurture` | Flow | Time-based nurture: if no activity in 7/14/30 days, escalate or reassign |
| `Lead_Conversion` | Flow (Screen) | Guided conversion with duplicate account/contact matching |
| `leadScoreCard` | LWC | Visual lead score breakdown with contributing factors |
| `leadConversionWizard` | LWC | Step-by-step conversion with mapping preview and merge options |
| Lead Validation Rules | ValidationRule | Email required, Company required, Phone format validation |
| Lead Assignment Rules | AssignmentRule | Territory + round-robin + capacity |

#### 4.2 Campaign Management Module

| Component | Type | Description |
|-----------|------|-------------|
| `Campaign` (standard) | CustomField additions | Campaign Cost Per Lead, ROI Calculator (formula), Target Segment |
| `CampaignMember` (standard) | CustomField additions | Response Quality Score, Conversion Attribution |
| `CampaignService` | Apex Class | ROI calculation, attribution modeling, member status management |
| `campaignDashboard` | LWC | Campaign performance overview with conversion funnel visualization |
| Campaign Reports | Report | Pipeline sourced by campaign, ROI by campaign type, conversion rates |

---

### Phase 5: Analytics, Reporting & Dashboards

**Goal:** Deliver actionable insights for sales leadership.

#### 5.1 Reports Module

| Report | Type | Description |
|--------|------|-------------|
| Pipeline by Stage | Matrix | Opportunity count and amount by stage, grouped by owner |
| Win/Loss Analysis | Summary | Closed Won vs Lost by competitor, region, product line |
| Sales Rep Scorecard | Summary | Activities, pipeline, conversion rate, avg deal size per rep |
| Forecast vs Actual | Matrix | Monthly/quarterly forecast accuracy tracking |
| Lead Conversion Funnel | Summary | Lead -> MQL -> SQL -> Opportunity -> Closed Won conversion rates |
| Activity Compliance | Tabular | Reps below minimum activity thresholds |
| Account Health | Summary | Accounts by score tier with risk indicators |

#### 5.2 Dashboards Module

| Dashboard | Components | Audience |
|-----------|------------|----------|
| Sales Executive Dashboard | Pipeline waterfall, forecast gauge, top deals, win rate trend | VP Sales / C-Suite |
| Sales Manager Dashboard | Team pipeline, activity metrics, rep leaderboard, deal aging | Sales Managers |
| Sales Rep Dashboard | My pipeline, my activities today, upcoming renewals, quota attainment | Individual Reps |
| Marketing ROI Dashboard | Campaign performance, lead source analysis, MQL generation trend | Marketing |

#### 5.3 Custom Analytics Components

| Component | Type | Description |
|-----------|------|-------------|
| `pipelineChart` | LWC | Interactive pipeline visualization with drill-down by stage/owner/product |
| `forecastGauge` | LWC | Quota attainment gauge with best-case/commit/closed segments |
| `winRateTrend` | LWC | 12-month rolling win rate chart with trend line |
| `leaderboard` | LWC | Gamified rep leaderboard with configurable metrics |

---

### Phase 6: Integration & External Connectivity

**Goal:** Connect Salesforce with external systems.

#### 6.1 Integration Framework

| Component | Type | Description |
|-----------|------|-------------|
| `IntegrationService` | Apex Class | Base class for all outbound callouts with retry, logging, circuit breaker |
| `IntegrationLog__c` | Custom Object | Tracks all inbound/outbound integration events: timestamp, payload, status, error |
| `CalloutMock` | Apex Class | Reusable HTTP callout mock for all integration tests |
| `IntegrationEndpoint__mdt` | CustomMetadata | Endpoint configuration without hardcoded URLs |
| Named Credentials | NamedCredential | OAuth/Basic auth configuration per external system |

#### 6.2 Common Integration Patterns

| Integration | Direction | Method | Description |
|-------------|-----------|--------|-------------|
| ERP (SAP/Oracle) | Bidirectional | REST API / Platform Events | Account sync, order push, inventory check |
| Marketing Automation | Outbound | REST API | Lead/contact sync, campaign response capture |
| Email Service | Inbound | Email-to-Case / Email Services | Inbound email parsing, auto-case creation |
| Document Generation | Outbound | REST API | Contract/proposal PDF generation via external service |
| Data Enrichment | Outbound | REST API | Account/lead enrichment from third-party data providers |

#### 6.3 Platform Events & Change Data Capture

| Component | Type | Description |
|-----------|------|-------------|
| `Order_Created__e` | Platform Event | Published when opportunity closes; consumed by ERP integration |
| `Lead_Qualified__e` | Platform Event | Published when lead score exceeds threshold; consumed by marketing |
| `Account_Updated__e` | CDC | Change Data Capture on Account for real-time external sync |
| `EventPublisher` | Apex Class | Centralized event publishing with error handling |
| `EventSubscriber` | Apex Trigger | Platform event trigger handlers with replay ID tracking |

---

### Phase 7: Security, Access Control & Governance

**Goal:** Implement enterprise-grade security model.

#### 7.1 Permission Architecture

| Component | Type | Description |
|-----------|------|-------------|
| `SFA_Sales_Rep` | PermissionSet | Read/Create/Edit on Leads, Contacts, Opportunities, Activities; No Delete |
| `SFA_Sales_Manager` | PermissionSet | Extends Rep + View All on team records, Approve Discounts, Run Reports |
| `SFA_Sales_Admin` | PermissionSet | Full CRUD on all SFA objects, Manage Territories, Import Data |
| `SFA_Executive` | PermissionSet | Read All on pipeline/forecast, Dashboard access, No Edit |
| `SFA_Integration_User` | PermissionSet | API-only access for integration user, specific object CRUD |
| Permission Set Groups | PSG | Group permission sets by role for simplified assignment |

#### 7.2 Data Access Model

| Mechanism | Scope | Description |
|-----------|-------|-------------|
| OWD (Org-Wide Defaults) | Org | Opportunities: Private; Accounts: Read; Leads: Private; Contacts: Controlled by Parent |
| Role Hierarchy | Vertical | Rep -> Manager -> Director -> VP -> SVP (roll-up visibility) |
| Sharing Rules | Horizontal | Territory-based sharing for cross-team collaboration |
| Manual Sharing | Ad-hoc | Allow reps to share specific records with peers |
| Apex Managed Sharing | Programmatic | Territory-based sharing calculated by `TerritoryShareService` |

#### 7.3 Field-Level Security

| Pattern | Description |
|---------|-------------|
| Sensitive Fields | Revenue, Discount %, Commission -- restricted to Manager+ |
| Integration Fields | External IDs, Sync Status -- visible only to Admin/Integration users |
| Audit Fields | Created By, Modified By, Last Activity -- read-only for all |

---

### Phase 8: Automation & Process Optimization

**Goal:** Reduce manual work through declarative and programmatic automation.

#### 8.1 Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| `Lead_Auto_Assignment` | Record-Triggered (After Create) | Lead created | Territory lookup -> queue assignment -> notification |
| `Lead_SLA_Monitor` | Scheduled | Daily at 8 AM | Flag leads not contacted within SLA window |
| `Opp_Stage_Validation` | Record-Triggered (Before Update) | Stage changed | Enforce required fields per stage |
| `Opp_Approval_Routing` | Approval Process | Discount > 15% | Route to Manager; > 25% to VP; > 40% to C-level |
| `Account_Health_Refresh` | Scheduled | Weekly | Recalculate account health scores |
| `Welcome_Email` | Record-Triggered (After Create) | Contact created with Onboarding role | Send welcome email template |
| `Contract_Renewal_Alert` | Scheduled | 90/60/30 days before expiry | Notify account owner of upcoming renewals |
| `Activity_Gap_Alert` | Scheduled | Daily | Flag accounts with no activity in 30+ days |

#### 8.2 Apex Batch & Scheduled Jobs

| Class | Type | Schedule | Description |
|-------|------|----------|-------------|
| `LeadScoreBatch` | Batch | Nightly | Recalculate all lead scores based on latest engagement data |
| `AccountHealthBatch` | Batch | Weekly | Aggregate activity, opportunity, and case data into health score |
| `DataCleanupBatch` | Batch | Monthly | Archive old integration logs, purge stale temp records |
| `ForecastSnapshotBatch` | Batch | Weekly (Friday PM) | Snapshot current forecast for historical trending |
| `SLAComplianceBatch` | Batch | Hourly | Check lead/case SLA compliance and flag violations |

---

### Phase 9: User Experience & Lightning App

**Goal:** Deliver a cohesive, performant user interface.

#### 9.1 Lightning App

| Component | Description |
|-----------|-------------|
| `SFA_App` | Custom Lightning App with branded navigation, utility bar, home page |
| Home Page | Executive summary: my pipeline, my activities today, team alerts |
| Utility Bar | Quick-log activity, global search, notification center |
| App Navigation | Leads -> Accounts -> Contacts -> Opportunities -> Reports -> Dashboards |

#### 9.2 Lightning Web Components (Full Catalog)

| Component | Location | Description |
|-----------|----------|-------------|
| `pipelineBoard` | Opportunity Tab | Kanban-style drag-drop pipeline management |
| `activityLogger` | Utility Bar | Quick activity entry with auto-populate from context |
| `activityTimeline` | Record Pages | Unified chronological activity feed |
| `contactCard` | Contact Record Page | Enhanced contact display with quick communication |
| `productCatalog` | Opportunity Related | Searchable product picker with bundle support |
| `productConfigurator` | Quote Related | CPQ-lite product bundling and pricing |
| `quoteBuilder` | Quote Record Page | Line item editor with real-time calculations |
| `leadScoreCard` | Lead Record Page | Visual score breakdown with trend |
| `leadConversionWizard` | Lead Record Page Action | Guided multi-step conversion flow |
| `accountHealthCard` | Account Record Page | Health score gauge with contributing factors |
| `forecastGauge` | Home Page / Dashboard | Quota attainment visualization |
| `pipelineChart` | Home Page / Dashboard | Interactive pipeline analytics |
| `winRateTrend` | Dashboard | Rolling win rate with trend line |
| `leaderboard` | Home Page | Gamified team performance ranking |
| `notificationCenter` | Utility Bar | Centralized alerts and action items |
| `globalSearchEnhanced` | Utility Bar | Cross-object search with recent items |

#### 9.3 Aura Components (Legacy Support)

| Component | Description |
|-----------|-------------|
| `QuickActions` | Aura wrapper for LWC quick actions (where LWC quick actions not supported) |
| `UtilityBarContainer` | Aura utility bar component wrapping LWC children |

---

### Phase 10: Testing & Quality Assurance

**Goal:** Achieve 85%+ code coverage with meaningful tests.

#### 10.1 Test Architecture

| Layer | Pattern | Description |
|-------|---------|-------------|
| Unit Tests | `*Test.cls` per class | Isolated logic testing with mocks/stubs |
| Integration Tests | `*IntegrationTest.cls` | Full DML, trigger, flow execution tests |
| Bulk Tests | Within each test class | 200+ record operations to validate governor limit compliance |
| Negative Tests | Within each test class | Invalid data, missing permissions, error paths |
| Test Data Factory | `TestDataFactory.cls` | Centralized test data creation with builder pattern |
| Mock Framework | `CalloutMock.cls` | HTTP callout mocking for integration tests |

#### 10.2 Quality Gates (CI/CD)

| Gate | Tool | Threshold |
|------|------|-----------|
| Apex Code Coverage | `sf apex run test` | Minimum 85% org-wide, 75% per class |
| Apex Static Analysis | PMD (Apex ruleset) | Zero Critical/High violations |
| LWC Linting | ESLint + LWC plugin | Zero errors, warnings reviewed |
| LWC Unit Tests | Jest (`@salesforce/sfdx-lwc-jest`) | All tests passing |
| Security Review | Salesforce Scanner (`sf scanner`) | Zero Critical findings |
| Deployment Validation | `sf project deploy start --dry-run` | Clean deployment |

---

## 5. Recommended Apex Architecture Patterns

### 5.1 Trigger Framework (Single Trigger Per Object)

```
Trigger (1 per object)
  -> TriggerHandler (abstract base class)
    -> [Object]TriggerHandler (concrete per object)
      -> [Object]Service (business logic)
        -> [Object]Selector (SOQL queries)
```

### 5.2 Service Layer Pattern

```
LWC / Flow / Trigger
  -> Service Class (stateless, bulkified)
    -> Selector Class (query encapsulation, FLS enforced)
    -> Domain Class (record-level validation, defaults)
```

### 5.3 Key Apex Classes (Planned)

| Class | Layer | Responsibility |
|-------|-------|----------------|
| `TriggerHandler` | Framework | Abstract base: before/after insert/update/delete routing, recursion guard |
| `Selector` | Framework | Abstract base: enforces FLS, standardizes query patterns |
| `TestDataFactory` | Test | Builder-pattern test data creation for all custom/standard objects |
| `ApplicationException` | Framework | Custom exception hierarchy for structured error handling |
| `Logger` | Framework | Centralized logging to `Integration_Log__c` or platform events |
| `FeatureFlag` | Framework | Custom metadata-driven feature toggling |

---

## 6. Implementation Priority Matrix

| Phase | Priority | Risk if Delayed | Dependency |
|-------|----------|-----------------|------------|
| Phase 1: CI/CD Hardening | **P0 - Critical** | Broken deployments, no quality gates | None |
| Phase 2: Data Model | **P0 - Critical** | Cannot build any features without objects | Phase 1 |
| Phase 3: Sales Process | **P1 - High** | Core SFA value proposition blocked | Phase 2 |
| Phase 4: Lead Management | **P1 - High** | Top-of-funnel blocked | Phase 2 |
| Phase 5: Analytics | **P2 - Medium** | Leadership visibility delayed | Phase 3, 4 |
| Phase 6: Integrations | **P2 - Medium** | Manual data entry continues | Phase 2 |
| Phase 7: Security | **P1 - High** | Must be in place before UAT/Go-Live | Phase 2 |
| Phase 8: Automation | **P2 - Medium** | Manual processes continue | Phase 3, 4 |
| Phase 9: User Experience | **P2 - Medium** | Adoption risk | Phase 3 |
| Phase 10: Testing/QA | **P0 - Critical** | Continuous; must parallel all phases | Phase 1 |

---

## 7. Technical Debt & Immediate Fixes

These items in the current codebase should be addressed before building on top:

| # | Item | File | Fix |
|---|------|------|-----|
| 1 | `main.yml` passes individual file paths to `--source-dir` which expects directories | `main.yml:52` | Adopt `sfdx-git-delta` plugin for proper delta package generation |
| 2 | `main.yml` has no test execution during deployment | `main.yml:52-56` | Add `--test-level RunLocalTests` flag |
| 3 | `main.yml` does not clean up `authfile.txt` | `main.yml` | Add cleanup step after deploy |
| 4 | `retrieve.yml` uses `actions/checkout@v3` (outdated) | `retrieve.yml:13` | Upgrade to `actions/checkout@v4` |
| 5 | Sample LWC uses `@track` unnecessarily | `skeleton.yml:316` | Remove `@track`; reactive by default since LWC v1.5 |
| 6 | `skeleton.yml` README has broken markdown escaping | `skeleton.yml:467-469` | Fix backtick escaping in heredoc |
| 7 | No `project-scratch-def.json` in skeleton | `skeleton.yml` | Add scratch org definition file generation |
| 8 | `package.xml` uses wildcard `*` for all types | `skeleton.yml:361-445` | Fine for dev, but should have targeted manifests for production |

---

## 8. Glossary

| Term | Definition |
|------|------------|
| **SFA** | Sales Force Automation -- the Salesforce application being built |
| **SFDX** | Salesforce Developer Experience -- modern CLI-based development model |
| **Delta Deploy** | Deploying only files that changed between commits (vs. full deploy) |
| **LWC** | Lightning Web Components -- modern Salesforce UI framework |
| **PMD** | Static code analyzer supporting Apex rules |
| **OWD** | Org-Wide Defaults -- baseline record sharing settings |
| **FLS** | Field-Level Security -- per-field visibility controls |
| **CPQ** | Configure-Price-Quote -- product configuration and pricing |
| **CDC** | Change Data Capture -- real-time data change streaming |
| **MQL/SQL** | Marketing/Sales Qualified Lead -- lead qualification stages |
