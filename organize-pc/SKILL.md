---
name: organize-pc
description: Structure a Windows PC into numbered, colour-coded, documented areas with the Folder Colors toolkit, and keep it that way. Use when the user asks to organise or tidy their PC, Desktop, Downloads, Documents, a drive or a cloud root; to set up or redo a folder structure; to process an inbox or transit folder; to write or refresh a folder README or SOP; to undo the last reorganisation; to update the PC map; or asks where something should go.
---

# organize-pc

The workflow layer over `folder-colors` (one level up: `..\Set-FolderColor.ps1`,
`..\categories.json`). It decides *where things live*; folder-colors colours and tags them.
Doctrine in `references\principles.md`, starting layouts in `references\presets.md`,
placement rules in `references\classify.md`, document skeletons in
`references\pc-map-template.md` and `references\readme-template.md`.

Scripts (Windows PowerShell 5.1, `powershell -NoProfile -ExecutionPolicy Bypass -File ...`):

| Script | Does |
|---|---|
| `scripts\Get-PcInventory.ps1 [-Roots ...]` | read-only scan of roots, JSON |
| `scripts\Move-Tracked.ps1 -Plan moves.json [-Apply]` | the only mover; dry run by default; logs every move |
| `scripts\Move-Tracked.ps1 -Undo [-Batch id]` / `-List` | reverse a batch; show batches |
| `scripts\Set-DownloadsPolicy.ps1 [-Days N] [-Apply]` | Storage Sense rule for Downloads |
| `scripts\Update-PcMap.ps1 [-RegisterTask]` | refresh the map's auto section; optional daily task |

The map is `%USERPROFILE%\PC-MAP.md`. The move log is
`%USERPROFILE%\.folder-colors\organize-log.jsonl`.

## Every run starts here

Read `PC-MAP.md`. If it exists, run `Update-PcMap.ps1` and read the auto section: folders
marked `unmapped` are the drift since last time; tell the user and carry them into whatever
step follows. No map means a first run.

## First run: structure the machine

1. **Interview, briefly.** Ask only what the inventory cannot tell: what the person does
   (the areas of work and life), which roots to organise, which preset to start from
   (`presets.md`; A unless told otherwise), cloud roots and what must stay local, Downloads
   retention (14 days default), whether the Desktop stays empty. Offer defaults; most
   answers are a yes. Completion: every question has an answer written down in the reply.
2. **Inventory.** `Get-PcInventory.ps1 -Roots <the roots>`. Summarise in one paragraph:
   counts, clusters, patterns, cloud roots, repositories, anything already coloured.
3. **Propose.** One table for the areas (number, name, path, category and colour,
   purpose), then one row per existing top-level folder and loose file: target, action
   (move as a unit, keep, archive, inbox) and the `classify.md` rule that placed it. Then
   the overlap check and the tie-break rules it produced. Depth three at most. Wait for
   approval or edits. Completion: the user has said yes to the table as shown.
4. **Execute, one batch per area.** Create the area, write the batch's `moves.json`, show
   the `Move-Tracked.ps1` dry run, apply, then colour and tag the area with
   `..\Set-FolderColor.ps1 -Path <area> -Category <name>`, write its `00_README.md` from
   `readme-template.md` with the rules this proposal produced, and report the count moved.
   After the last area: write `PC-MAP.md` from `pc-map-template.md`, run `Update-PcMap.ps1`,
   apply `Set-DownloadsPolicy.ps1 -Days N -Apply` if agreed, and offer `-RegisterTask`.
5. **Verify.** `Get-PcInventory.ps1` again: every approved row sits where the table said,
   every area answers `-Get` with its category, every area has a README, the map's auto
   section shows zero unmapped folders. Show the table with a result column. Completion:
   every row reads done, or names what is left and why.

## Later runs

- **Tidy** ("tidy my Downloads / Desktop / inbox"): inventory the transit folders, place
  each item with `classify.md` against the map and the area READMEs, propose the table,
  move tracked, report. Items untouched for 90 days in active areas are listed as archive
  candidates, never moved without a yes.
- **Drift**: an unmapped folder is either a new area (add it to the map's table, colour it,
  write its README) or something that belongs inside an existing area (propose the move).
- **Where does X go**: answer from the map and the READMEs, quoting the rule; if no rule
  covers it, propose one and add it to the README that should own it.
- **Undo**: `Move-Tracked.ps1 -List`, then `-Undo -Batch <id>`; report what came back.

## Rules

- A move happens after the user approves the row that describes it, and through
  `Move-Tracked.ps1` only, so the log can reverse it.
- Finished things are archived; the skill deletes nothing. Duplicates are shown side by
  side and left to the user.
- Cloud roots and git repositories move as units and are organised inside; system and
  application folders are not in the proposal.
- Areas are `NN_NAME` with `00_README.md` first; three levels deep at most.
- One category per area; subfolders get a colour only when asked.
