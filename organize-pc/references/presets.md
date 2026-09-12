# Presets

Starting layouts. The interview picks one; the proposal adapts it to what the inventory
found (an area with nothing to hold is dropped, an obvious missing one is added). Category
names are the ones in `categories.json`; the colour follows from them.

## A. Solo business + personal (default)

| Area | Category | Holds |
|---|---|---|
| `00_INBOX` | Urgent | unsorted and in-flight items; emptied weekly |
| `01_CLIENTS` | Clients | one folder per client, cloned from `10_TEMPLATES\Client` |
| `02_BUSINESS` | Business | company operations, offers, planning, SOPs |
| `03_MARKETING` | Marketing | content, campaigns, ads, brand copy |
| `04_FINANCE` | Finance | invoices, bookkeeping, tax by year (`2026\`) |
| `05_LEGAL_ADMIN` | Legal & Admin | contracts, entity papers, insurance, government |
| `06_CODE` | Code | repositories, each one a unit |
| `07_DESIGN_MEDIA` | Design | brand assets, mockups, video, audio, photos for work |
| `08_LEARNING` | Learning | courses, books, study notes |
| `09_PERSONAL` | Health & Personal | health, home, family admin, personal photos |
| `10_TEMPLATES` | Templates | starting points; cloned, never edited in place |
| `99_ARCHIVE` | Archive | finished work by year; read-only in spirit |

Client template (`10_TEMPLATES\Client`):

```
01_Onboarding      signed agreement, intake, access
02_Strategy        audit, plan, targets
03_Deliverables    the work, final versions only
04_Raw_Inputs      recordings, client-supplied files
05_Reporting       scorecards, monthly reports
00_README.md
```

## B. $100M value chain (a business-only machine)

Hormozi's four functions plus what keeps them running.

| Area | Category | Holds |
|---|---|---|
| `00_DAILY_EXECUTION` | Urgent | today's volume work; wiped at end of day |
| `01_LEADS_ATTENTION` | Marketing | outreach lists, content assets, ads, affiliates |
| `02_SALES_CONVERSION` | Business | offers, scripts, decks, objection handling |
| `03_DELIVERY` | Clients | client folders, onboarding, product assets |
| `04_FINANCE_LEGAL` | Finance | P&L, contracts, entity, tax |
| `05_OPERATIONS_TEAM` | Reference | SOPs, hiring, scorecards, training |
| `06_TEMPLATES` | Templates | outreach scripts, ad templates, trackers |
| `99_ARCHIVE` | Archive | closed clients and finished campaigns |

## Mapping the leftovers

Categories with no area of their own still label subfolders when useful: `Ideas & Drafts`
for a scratch folder inside an area, `Private` for a passwords or identity folder,
`Data & Backups` for exports, `System & Tools` for installers and scripts, `Media` for a
footage folder inside `07_DESIGN_MEDIA`. Colour a subfolder only when it earns a glance.
