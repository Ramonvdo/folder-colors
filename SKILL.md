---
name: folder-colors
description: Colour-code Windows folders by category using the Folder Colors toolkit (20 Windows 11 folder icons, each mapped to a category in categories.json). Use when the user asks to colour, recolour or reset a folder; to organise or colour-code a directory by category; to add, rename, regroup or reassign a category; or to install, repair or remove the right-click "Folder Color" menu.
---

# folder-colors

Everything lives next to this file: `Set-FolderColor.ps1` (the engine), `categories.json`
(the mapping index -> colour -> category -> group; the only file a user edits),
`install.ps1` / `uninstall.ps1` (the right-click menu) and `assets\Windows_11_coloured_icons.icl`.
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

## One folder

Run the engine, then `-Get` and confirm the reported index is the one requested. Explorer
repaints the icon straight away; if a window still shows the old icon, F5 in that window.

## Organise a directory by category

1. Confirm the target root with the user. Top level only, unless they ask for recursion.
   Roots to leave alone entirely: `C:\Windows`, `Program Files*`, `AppData`, `.git`,
   `node_modules`.
2. List its subfolders (`Get-ChildItem -Directory`) and `-Get` each one for its current
   colour.
3. Assign each subfolder one category from `categories.json`, judging by the name first and
   a glance at a few filenames when the name is ambiguous. `hints` in the JSON are
   tie-breakers, not rules. A folder that fits nothing stays uncoloured; forcing a fit is
   worse than leaving it plain.
4. Show a table (folder, current, proposed, one-line reason) and wait for approval or edits.
5. Apply one engine call per approved row, then `-Get` every row again. Done when every
   approved row reports its proposed index; show the final table with a result column.

## Change the categories or groups

Edit `categories.json`: 20 entries, indices 0..19 each used once, unique category and
colour names, every `group` present in the `groups` list. Array order is menu order inside
a group. Explorer caps a cascade at 16 entries, so keep at most 16 categories per group and
at most 15 groups. Then run `install.ps1` to rebuild the menu. Folders already coloured
keep their colour.

## Menu: install, repair, remove

- `install.ps1`: no admin needed; it writes only
  `HKCU\Software\Classes\Directory\shell\FolderColors` and rebuilds it from scratch each
  run. Re-run it after editing `categories.json` or moving this folder (the menu stores
  absolute paths).
- `uninstall.ps1`: removes that key. Coloured folders keep their icons for as long as this
  folder exists; `-Reset` any the user wants plain.
- On the Windows 11 default menu the entry sits under "Show more options" (Shift+F10). On
  the classic menu it is at the top level.

## Gotchas

- OneDrive syncs `desktop.ini`. A colour set here shows on another machine only if the
  same `.icl` path exists there.
- Colouring a drive root goes through the engine, not the menu (Explorer treats drives as
  a different class).
