---
name: organize-pc
description: Structure a Windows PC into numbered, colour-coded, documented areas with the Folder Colors toolkit, and keep it that way: spot what is missing or worn out and offer a structure for it, restructure only after a yes, keep a map any LLM reads first. Use when the user asks to organise or tidy their PC, Desktop, Downloads, Documents, a drive or a cloud root; to set up, adopt or redo a folder structure; to process an inbox or transit folder; to write or refresh a folder README or SOP; to check how their PC is doing; to undo the last reorganisation; to update the PC map; or asks where something should go. Inside one folder that is not a transit folder, tidy-folder; colour alone, auto-color.
---

# organize-pc

The workflow layer over `folder-colors`. It decides *where things live*; folder-colors
colours and tags them. Find the engine and the repo root as `..\..\shared\tools.md`
describes (read it once per run). Doctrine in `references\principles.md`, starting layouts
and adopt mode in `references\presets.md`, placement rules in `references\classify.md`,
protected units in `..\..\shared\protected-units.md`, document skeletons in
`references\pc-map-template.md` and `references\readme-template.md`, sources in
`references\sources.md`.

Scripts (Windows PowerShell 5.1, `powershell -NoProfile -ExecutionPolicy Bypass -File ...`):

| Script | Does |
|---|---|
| `scripts\Get-PcInventory.ps1 [-Roots ...]` | read-only scan of roots, JSON; marks git repos, workspaces, cloud roots |
| `scripts\Move-Tracked.ps1 -Plan moves.json [-Apply]` | the only mover; dry run by default; logs every move |
| `scripts\Move-Tracked.ps1 -Undo [-Batch id]` / `-List` | reverse a batch; show batches |
| `scripts\Set-DownloadsPolicy.ps1 [-Days N] [-Apply]` | Storage Sense rule for Downloads |
| `scripts\Update-PcMap.ps1 [-RegisterTask]` | refresh the map's auto section; optional daily task |
| `scripts\Get-PcHealth.ps1` | the audit table |

The map is `%USERPROFILE%\PC-MAP.md`. The move log is
`%USERPROFILE%\.folder-colors\organize-log.jsonl`.

## The one rule

Every change waits for a yes on the row that describes it: each move, each rename, each
new area, each README, each policy. The user's own layout, names and preferences win over
any preset; a preset is an offer. Protected units (a repository, a workspace with
`CLAUDE.md` or `AGENTS.md`, a vault, a cloud root) move whole and are never rearranged
inside.

## Every run starts here

Read `PC-MAP.md`. If it exists, run `Update-PcMap.ps1` and read the auto section: folders
marked `unmapped` are the drift since last time; carry them into whatever follows. No map
means a first run. Then run **Identify** (below) and put its questions to the user before
anything else; the user picks which to act on, if any.

## Identify: opportunities, as questions

Compare what exists with the map, the preferences and what the person does. Each finding
is a question with an offer, never an action:

- a kind of record with no home ("no finance records folder for <business>: where do you
  keep them, and shall I set the finance structure up there?");
- an old structure that fights its purpose ("`Administration` numbers its folders
  `1_..12_`, which sorts 1, 10, 11, 12, 2; want it laid out as the finance profile?");
- an area without a `00_README.md`, an area without a colour, a transit folder that is
  full, folders untouched for the retention window that could go to the archive;
- a folder that looks like a workspace but carries no marker (offer to leave it alone).

A yes turns the item into the matching workflow below (or into tidy-folder for a single
folder). A no is recorded in the map's Preferences so the question is not asked again.

## First run: structure the machine

1. **Interview, briefly.** Only what the inventory cannot tell: what the person does (the
   areas of work and life), which roots to organise, whether they want a preset (A, B, C
   in `presets.md`) or to keep their own top-level folders (adopt mode), which numbering if
   any, cloud roots and what must stay local, Downloads retention, whether the Desktop
   stays empty, folders that are off-limits. Offer defaults; most answers are a yes.
   Completion: every answer written into the reply, and later into the map's Preferences.
2. **Inventory.** `Get-PcInventory.ps1 -Roots <the roots>`. Summarise in one paragraph:
   counts, clusters, patterns, cloud roots, repositories and workspaces, anything already
   coloured (an existing colour is the user telling you what a folder is).
3. **Propose.** One table for the areas (number or name as chosen, path, category and
   colour, purpose), then one row per existing top-level folder and loose file: target,
   action (move as a unit, keep, rename, archive, inbox) and the `classify.md` rule that
   placed it. Then the overlap check and the tie-break rules it produced. Depth three at
   most. Wait for approval or edits. Completion: the user has said yes to the table as
   shown.
4. **Execute, one batch per area.** Create the area, write the batch's `moves.json`, show
   the `Move-Tracked.ps1` dry run, apply, then colour and tag the area with
   `<root>\Set-FolderColor.ps1 -Path <area> -Category <name>`, write its `00_README.md`
   from `readme-template.md` with the rules this proposal produced, and report the count
   moved. After the last area: write `PC-MAP.md` from `pc-map-template.md` (Preferences
   filled from step 1), run `Update-PcMap.ps1`, apply `Set-DownloadsPolicy.ps1 -Days N
   -Apply` if agreed, offer `-RegisterTask`.
5. **Verify.** `Get-PcHealth.ps1`: every area coloured and documented, zero unmapped
   folders, transit folders within limits. Show the table. Completion: every row reads
   ok, or names what is left and why.

## Later runs

- **Tidy** ("tidy my Downloads / Desktop / inbox"): inventory the transit folders, place
  each item with `classify.md` against the map and the area READMEs, propose the table,
  move tracked, report. Items untouched for the retention window in active areas are
  listed as archive candidates, never moved without a yes.
- **Drift**: an unmapped folder is either a new area (add it to the map's table, colour
  it, write its README) or something that belongs inside an existing area (propose the
  move). A workspace marker means: list it, leave it.
- **Health** ("how is my PC doing"): `Get-PcHealth.ps1`, then the Identify questions for
  every row that needs attention.
- **Where does X go**: answer from the map and the READMEs, quoting the rule; if no rule
  covers it, propose one and add it to the README that should own it.
- **Undo**: `Move-Tracked.ps1 -List`, then `-Undo -Batch <id>`; report what came back.
