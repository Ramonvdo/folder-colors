# Security

## What this project does on your machine

- Writes one registry key for the current user:
  `HKCU\Software\Classes\Directory\shell\FolderColors`. Nothing under `HKLM`, so no
  administrator rights are needed or requested.
- Writes a hidden `desktop.ini` into folders you choose to colour, and sets the
  read-only and system attributes Windows needs to honour it.
- Runs `powershell.exe` with `-ExecutionPolicy Bypass` for its own scripts only, from the
  path recorded at install time, started through `run-hidden.vbs` (`wscript.exe`) so no
  console window appears.
- Writes the category name into the folder's Tags and Categories properties, in the same
  `desktop.ini`.
- `install.ps1` records the checkout path in `%USERPROFILE%\.folder-colors\config.json`
  so the skills can find the scripts; nothing else is stored there.
- The organize-pc and tidy-folder skills move files only through
  `skills\organize-pc\scripts\Move-Tracked.ps1`,
  which refuses to overwrite and logs every move to
  `%USERPROFILE%\.folder-colors\organize-log.jsonl` so a batch can be undone. It never
  deletes. Its optional Downloads rule sets the same Storage Sense values as Settings does;
  its optional daily task runs `Update-PcMap.ps1`, which only rewrites a marked section of
  `%USERPROFILE%\PC-MAP.md`.
- Makes no network connections and collects nothing.

The icon library (`.icl`) is a resource-only DLL: it contains icons and no code. See
`NOTICE.md` for its origin.

Things to know:

- `run-hidden.vbs` starts only the three scripts of this repo and nothing else. The menu
  entry and the optional task point at your checkout, so keep the checkout in a folder
  only your account can write to; anything that can edit those files runs as you.
- Colouring a junction or symbolic link writes the `desktop.ini` into its target folder.
- The Downloads rule is Storage Sense deleting files on a schedule; it is applied only when
  you run `Set-DownloadsPolicy.ps1 -Apply` (or say yes when the skill offers it), and it is
  reversible with `-Days 0`.
- Moving a folder to another volume is a copy followed by a delete; `Move-Tracked.ps1`
  refuses it unless you pass `-AllowCrossVolume`.

## Reporting a vulnerability

Open a private security advisory on the GitHub repository ("Security" tab, "Report a
vulnerability"). Please include the Windows build and the steps to reproduce.
