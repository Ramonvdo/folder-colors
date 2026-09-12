# Principles

The doctrine organize-pc applies. Read once per run; every proposal is checked against it.
Distilled from Alex Hormozi's operating rules (subtraction, volume, no organisation
theatre), the `organize-folder` skill's process discipline, and LLM-wiki conventions.

## Areas

- A machine has a handful of **areas**, each one top-level folder named `NN_NAME`
  (`01_CLIENTS`). The number is the sort order and the priority. Between six and twelve
  areas; a preset gives the starting set.
- Each area has one **category** from `categories.json`, which gives it its colour and its
  Tags/Categories entry. One area, one category; two areas may share a category only when
  they are the same kind of thing on different drives.
- **Depth of three** inside an area (`01_CLIENTS\Acme\03_Deliverables\file.pdf`). A file
  that needs a fourth level is a sign the area needs a template, not a deeper tree.
- Every area starts with **`00_README.md`**: the folder's SOP, pinned at the top by its
  name. Anyone (a contractor, next year's you, an LLM) opens the area and knows how it works
  without asking.
- **`10_TEMPLATES`** holds starting points (client folder, proposal, invoice, README).
  Templates are cloned, never edited in place.
- **`99_ARCHIVE\<year>\`** is where finished things go. Nothing active lives there.
  Archiving replaces deleting: the skill never deletes a user file.

## Transit folders

- **Downloads** has no subfolders. It is a landing strip: a file is processed the day it
  arrives (used, filed into its area, or left to expire). Storage Sense deletes what has not
  been touched for the retention period: 14 days by default (Windows offers 1, 14, 30 or
  60; Hormozi's 7 is not on the list, so 14 is the closest honest setting).
- **Desktop** ends the day empty. Whatever lands there is in-flight work.
- **`00_INBOX`** is the holding pen for things without an obvious home and for the weekly
  tidy. It is emptied every week; anything still there after two weeks goes to the archive.

## Naming

- Dated assets: `YYYY-MM-DD_Type_Name_vN` (`2026-09-12_Proposal_Acme_v2.pdf`). Sorting
  by name is sorting by date; search finds by type or name.
- Evergreen files keep a plain descriptive name (`Brand guidelines.pdf`).
- Client folders: `ClientName` (one word if possible); a client's subfolders follow the
  template in `10_TEMPLATES\Client`.
- Areas are uppercase with underscores; everything inside is normal Title Case.

## Cloud and local

- Heavy working files stay local (video, raw exports, code builds, anything you edit all
  day). Deliverables, SOPs, contracts and client-facing assets live in the cloud root so a
  dead laptop costs nothing.
- Cloud roots (OneDrive, Google Drive, Dropbox) and git repositories are **units**: the
  skill organises inside them and never moves them.

## Audit

- Weekly: transit folders empty, `00_INBOX` processed, anything untouched for 90 days in
  an active area listed as an archive candidate.
- The map (`PC-MAP.md`) is updated whenever an area is added, renamed or retired, and its
  auto section refreshes from the inventory.
