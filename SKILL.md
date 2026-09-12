---
name: folder-colors
description: Colour and tag one Windows folder by category with the Folder Colors toolkit (20 Windows 11 folder icons, each mapped to a category in categories.json). Use when the user asks to colour, recolour, tag or reset a folder or a few named folders; to add, rename, regroup or reassign a category; or to install, repair or remove the right-click "Folder Color" entry. Organising a whole directory, drive or PC belongs to the organize-pc skill.
---

# folder-colors

Everything lives next to this file: `Set-FolderColor.ps1` (the engine), `categories.json`
(the mapping index -> colour -> category -> group; the only file a user edits),
`Pick-FolderColor.ps1` (the palette the right-click entry opens), `install.ps1` /
`uninstall.ps1` (the right-click entry) and `assets\Windows_11_coloured_icons.icl`.
Run scripts with Windows PowerShell 5.1:
`powershell -NoProfile -ExecutionPolicy Bypass -File "<this dir>\Set-FolderColor.ps1" ...`

## Engine

| Task | Command |
|---|---|
| List categories | `Set-FolderColor.ps1 -List` |
| Read a folder's colour | `Set-FolderColor.ps1 -Path <dir> -Get \| Format-List` |
| Colour a folder | `Set-FolderColor.ps1 -Path <dir> -Category "Clients"` (or `-Color "Light Blue"`, or `-Index 12`) |
| Back to default | `Set-FolderColor.ps1 -Path <dir> -Reset` |

Names match loosely (`light-blue`, `LightBlue` and `Light Blue` are the same). The colour
is stored in the folder's hidden `desktop.ini` as an **index**, so a category can be
renamed or regrouped later without touching any folder. Exit code 0 means applied; a
non-zero exit carries the reason on stderr.

A folder that already has a `desktop.ini` (folder-type template, folder picture, an icon
set through Properties) keeps it: the engine replaces only the icon lines, remembers the
previous icon and the folder's attributes, and `-Reset` puts both back. `-Get` reports an
empty index for a folder whose `desktop.ini` this tool has not touched.

Colouring also writes the category name into the folder's Tags and Categories properties
(Explorer columns and Group by; Windows Search does not index folder tags). Tags the folder
already had stay; `-Reset` removes only ours. `"writeTags": false` in `categories.json`
turns this off.

## One folder

Run the engine, then `-Get` and confirm the reported index is the one requested. Open
Explorer windows repaint on their own.

## Many folders, a whole directory, the PC

That is `organize-pc` (`organize-pc\SKILL.md` in this repo, `/organize-pc` when
installed): it decides where things live, moves them with an undo log, writes the area
READMEs and the PC map, and calls this engine for the colouring. Hand over rather than
colouring folder by folder.

## Change the categories or groups

Edit `categories.json`: 20 entries, indices 0..19 each used once, unique category and
colour names, every `group` present in the `groups` list. Array order is tile order inside
a group. The palette reads the file when it opens, so no reinstall is needed. Folders
already coloured keep their colour; their tags keep the old name until recoloured.

## Menu: install, repair, remove

- `install.ps1`: no admin needed; it writes only
  `HKCU\Software\Classes\Directory\shell\FolderColors` (one "Folder Color..." entry that
  opens the palette) and rebuilds it from scratch each run. Re-run it after moving this
  folder (the entry stores absolute paths).
- `uninstall.ps1`: removes that key. Coloured folders keep their icons for as long as this
  folder exists; `-Reset` any the user wants plain.
- On the Windows 11 default menu the entry sits under "Show more options" (Shift+F10). On
  the classic menu it is at the top level.

## Gotchas

- OneDrive syncs `desktop.ini`. A colour set here shows on another machine only if the
  same `.icl` path exists there.
- Colouring a drive root goes through the engine, not the menu (Explorer treats drives as
  a different class).
