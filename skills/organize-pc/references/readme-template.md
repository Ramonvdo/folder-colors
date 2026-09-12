# 00_README.md template (one per area)

The area's SOP. Named `00_README.md` so it sorts to the top. Short: a newcomer reads it in
under a minute and files correctly. Write it from what the proposal decided for this area,
never from boilerplate; every rule in it should be one the overlap check or the interview
actually produced.

````markdown
---
type: area-readme
area: {01_CLIENTS}
category: {Clients}
color: {Light Blue}
updated: {YYYY-MM-DD}
map: file:///{C:/Users/name}/PC-MAP.md
---

# {01_CLIENTS}

## Purpose

{One sentence: what this area is for and what "done" looks like inside it.}

## What belongs here

- {one folder per client, named `ClientName`}
- {each client folder cloned from `10_TEMPLATES\Client`}

## What goes elsewhere

- {Client invoices: `04_FINANCE\Invoices\{Client}`}
- {Finished clients: `99_ARCHIVE\{year}\Clients\`}

## Naming

- {Folders: `ClientName`}
- {Files: `YYYY-MM-DD_Type_Name_vN`}

## Rules

- {New client: copy the template, rename, fill `01_Onboarding` first.}
- {Nothing deeper than `Client\03_Deliverables\file`.}

## Owner

{Name}. {Where to ask when something does not fit.}
````
