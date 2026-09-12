# Presets

Starting layouts, never a verdict. The interview offers them; the user may take one,
mix two, or keep their own top-level folders (adopt mode, at the end). The proposal adapts
whatever was chosen to what the inventory found: an area with nothing to hold is dropped,
an obvious missing one is offered as a question. Category names are the ones in
`categories.json`; the colour follows from them. Sources: `sources.md`.

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

## C. PARA (Forte): by actionability, for anyone

Four areas, no business assumption. From Forte's definitions: a project is a short-term
effort with a goal, an area needs ongoing attention, a resource is a topic of interest,
the archive is what is no longer active. Things move down the list as they cool off.

| Area | Category | Holds |
|---|---|---|
| `01_PROJECTS` | Active Projects | one folder per effort with an end (a launch, a move, a course you are taking now) |
| `02_AREAS` | Business | one folder per ongoing responsibility (a company, health, home, a client) |
| `03_RESOURCES` | Reference | topics, courses, templates, collected material |
| `04_ARCHIVE` | Archive | anything from the three above that went quiet |

Subfolders inside `02_AREAS` take the category that fits them (`Finance`, `Clients`,
`Health & Personal`), so the colours still say what a folder is.

## Numbering: two styles

- **Plain** (`NN_NAME`): the default here. Two digits, an underscore, a name in capitals.
  Sort order is the number.
- **Johnny.Decimal**: areas as tens (`10-19 Company`, `20-29 Personal`), categories inside
  them (`11 Finance`, `12 Clients`), IDs for folders (`11.01 Invoices received`). At most
  ten of each level, which is the point: "The ID tells us exactly where a thing is", and
  numbers keep folders from reordering when a new one arrives. Offer it to a user who
  already uses it or asks for it; it changes every folder name, so it is a yes per level.

## Adopt mode: the user's own layout

When the user's existing top-level folders already say what they hold, the areas *are*
those folders. Nothing is renamed. Offered one by one, each a separate yes: a number prefix,
a colour and tag, a `00_README.md`, an entry in the map. A user who says "keep my names"
gets colours, READMEs and a map, and keeps their names.

## Mapping the leftovers

Categories with no area of their own still label subfolders when useful: `Ideas & Drafts`
for a scratch folder inside an area, `Private` for a passwords or identity folder,
`Data & Backups` for exports, `System & Tools` for installers and scripts, `Media` for a
footage folder inside `07_DESIGN_MEDIA`. Colour a subfolder only when it earns a glance.
