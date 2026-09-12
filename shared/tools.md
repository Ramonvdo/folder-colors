# Finding the tools

Every skill in this repo calls the same scripts, which live at the repo root and in
`skills\organize-pc\scripts`. A skill never assumes its own location says where the root
is: a skill directory may be a junction, a plugin-cache copy, or the checkout itself.

Resolve `<root>` in this order and use the first that contains `Set-FolderColor.ps1`:

1. `%USERPROFILE%\.folder-colors\config.json`, key `root` (written by `install.ps1`).
2. Two levels up from the skill's own directory (`skills\<name>\..\..`), which is right
   inside the checkout and inside a plugin cache.
3. Ask the user where the checkout is, then suggest running `install.ps1` there so step 1
   works next time.

With `<root>` known:

| Tool | Path | Does |
|---|---|---|
| engine | `<root>\Set-FolderColor.ps1` | colour, tag, read, reset one folder |
| categories | `<root>\categories.json` | index -> colour -> category -> group, hints |
| palette | `<root>\Pick-FolderColor.ps1` | the right-click window |
| inventory | `<root>\skills\organize-pc\scripts\Get-PcInventory.ps1` | read-only scan, JSON |
| mover | `<root>\skills\organize-pc\scripts\Move-Tracked.ps1` | the only thing that moves files; logged; `-Undo` |
| map refresh | `<root>\skills\organize-pc\scripts\Update-PcMap.ps1` | auto section of `PC-MAP.md` |
| health | `<root>\skills\organize-pc\scripts\Get-PcHealth.ps1` | the audit table |
| batch colour | `<root>\skills\auto-color\scripts\Set-FolderColors.ps1` | many folders, JSON in |
| folder profile | `<root>\skills\tidy-folder\scripts\Get-FolderProfile.ps1` | one folder's files, JSON |

Run every script as `powershell -NoProfile -ExecutionPolicy Bypass -File "<path>" ...`.
State files: `%USERPROFILE%\PC-MAP.md` (the map),
`%USERPROFILE%\.folder-colors\organize-log.jsonl` (every move), `config.json` (root).
