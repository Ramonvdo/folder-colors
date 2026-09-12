---
name: auto-color
description: Colour and tag many existing folders at once with the Folder Colors toolkit, without moving anything: every subfolder of a directory, a project or workspace (src, docs, tests, assets), or the roots of the whole PC; also scan for uncoloured or untagged folders. Use when the user asks to colour, tag or colour-code a folder tree, a project, a workspace or their PC, or to find folders that have no colour yet. One named folder is folder-colors; restructuring or moving is organize-pc.
---

# auto-color

Colour is reversible and moves nothing, so this skill runs with one table and one yes.
Read `..\..\shared\tools.md` once per run to find the engine and the inventory; read
`..\..\shared\protected-units.md` before the table. The category names come from
`<root>\categories.json`; project folder names map through `references\workspace-map.json`.

## Steps

1. **Scope.** The directory the user named; "this project" or "this workspace" means the
   current working directory's repository root; "my PC" means the roots listed in
   `%USERPROFILE%\PC-MAP.md` (no map: ask which roots). Say the scope back in one line.
2. **Inventory.** `Get-PcInventory.ps1 -Roots <scope>`; for a project also its second
   level (`-Roots <root>, <root>\src, ...` for the folders that have children). Skip the
   `skip` names in `workspace-map.json` and the inside of protected units; a unit's own
   folder is still a candidate.
3. **Assign.** For each folder, one category or none:
   - a project folder name matches a rule in `workspace-map.json`;
   - otherwise the folder's own README says what it is; otherwise its name and the
     `hints` in `categories.json`; otherwise a glance at a few file names;
   - already coloured and the colour fits: keep, say so; already coloured and wrong: propose
     the change, with the reason;
   - nothing fits: leave it plain. A plain folder beats a wrong colour.
4. **One table, one yes.** Columns: folder, current, proposed, reason. Wait for the yes or
   the edits. A user who said "just do it" or "no need to ask" in the request gets the
   table applied without the pause, and sees the table afterwards.
5. **Apply.** Write the approved rows to a JSON plan (`[{ "path", "category" }]`, `none`
   to reset) and run `skills\auto-color\scripts\Set-FolderColors.ps1 -Plan <file>`. It
   colours through the engine, verifies each row with `-Get`, and inside a git repository
   adds `desktop.ini` to `.git\info\exclude` so `git status` stays clean. Completion: the
   script reports every row applied; show its table. Rows it could not apply are named
   with the reason.

## Scan for uncoloured folders

"Which folders have no colour?" is steps 1 and 2 followed by a list of the plain folders
with a suggested category each (step 3 without applying), then the offer to apply.

## Workspace notes

- Colouring a project touches only `desktop.ini` files and `.git\info\exclude`; the
  project's own `.gitignore`, `CLAUDE.md` and code are not edited. Add a line about the
  colours to the project's `CLAUDE.md` only when the user asks.
- Generated folders (`node_modules`, `dist`, `build`, `.venv`, ...) stay plain; they come
  and go.
- Two folders with the same name at different depths get the same category; that is the
  point of a workspace map.
