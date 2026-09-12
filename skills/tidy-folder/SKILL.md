---
name: tidy-folder
description: Bring order inside one folder full of loose files: group them into a few subfolders by topic or type, normalise file names to YYYY-MM-DD_Type_Name, and for a finance folder (tagged Finance, or said to be) apply the strict record-keeping profile: jurisdiction first, then year and document-type filing with invoice names read from the documents themselves. Use when the user asks to tidy, sort, clean up or rename the files in a folder, to set up or fix a finance, invoices, receipts or administration folder, or to file the PDFs dropped into one. A transit folder on a mapped PC (Downloads, Desktop, inbox) belongs to organize-pc; colouring alone is auto-color.
---

# tidy-folder

One folder, no map needed. Read `..\..\shared\tools.md` once per run to find the scripts;
read `..\..\shared\protected-units.md` before proposing anything. Rules for ordinary
folders are in `references\grouping.md`; the finance profile in `references\finance.md`
with its jurisdiction files in `references\jurisdictions\`.

## Steps

1. **Profile.** `skills\tidy-folder\scripts\Get-FolderProfile.ps1 -Path <folder>` and
   summarise in one paragraph: how many loose files, the clusters, dates, existing
   subfolders (protected units named as such), duplicate-suffix names, double extensions,
   and the folder's category. If the folder is a protected unit itself, stop and say why.
2. **Which profile.** Category `Finance`, a name like invoices, administration,
   bookkeeping, or the user saying so: the finance profile, and its jurisdiction questions
   come first (`finance.md`, "Jurisdiction first"). Otherwise `grouping.md`.
3. **Propose grouping.** At most five subfolders, each with the files it takes and the
   rule that placed them; the overlap check; the files that stay loose; duplicates listed
   side by side. Wait for the yes or the edits.
4. **Apply grouping.** Write the plan (`[{ "from", "to" }]`, `to` being the full new
   path) and run `Move-Tracked.ps1 -Plan <file>` for the dry run, then `-Apply`. One batch.
5. **Propose names.** For every file not yet in the pattern: the new name, the date source
   (document, file name, or last-write), the type, the topic or party. Finance folders:
   read each PDF (the Read tool handles PDFs) and take date, party, number, amount from
   the print; a row the document cannot answer says "needs you". Wait for the yes.
6. **Apply names.** A second `Move-Tracked.ps1` batch (renames are moves), so grouping and
   naming can be undone separately. Double extensions are fixed in this batch.
7. **Verify.** Profile again: zero loose files that should have moved, every renamed file
   matching the pattern, a `00_README.md` present for finance folders (write it from
   `finance.md`, "What the README says"). Show the final table with a result column.
   Offer `auto-color` for the new subfolders.

## Finance folder, first time

The profile asks the jurisdiction questions, proposes the year and type structure from
`finance.md`, and shows how each existing file maps into it, in the same table as steps 3
and 5. Existing subfolders that already match the structure are kept; ones that do not
(placeholder folders, unnumbered or wrongly numbered ones) are proposed as renames or
merges, never silently changed. The folder root becomes the inbox: anything dropped there
later is filed by running this skill again.

## Rules

- Moves and renames happen after the yes, through `Move-Tracked.ps1` only.
- Nothing is deleted; duplicates are shown, not removed.
- Protected units are left whole and unopened.
- The user's existing naming and folder style wins over the defaults when the two clash,
  except inside a finance folder, where the profile is the rule and the reason is stated.
