# Security

## What this project does on your machine

- Writes one registry key for the current user:
  `HKCU\Software\Classes\Directory\shell\FolderColors`. Nothing under `HKLM`, so no
  administrator rights are needed or requested.
- Writes a hidden `desktop.ini` into folders you choose to colour, and sets the
  read-only and system attributes Windows needs to honour it.
- Runs `powershell.exe` with `-ExecutionPolicy Bypass` for its own script only, from the
  path recorded at install time.
- Makes no network connections and collects nothing.

The icon library (`.icl`) is a resource-only DLL: it contains icons and no code. See
`NOTICE.md` for its origin.

## Reporting a vulnerability

Open a private security advisory on the GitHub repository ("Security" tab, "Report a
vulnerability"). Please include the Windows build and the steps to reproduce.
