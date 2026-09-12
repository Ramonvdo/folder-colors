# Protected units and the skip list

Shared by every skill in this repo. A **unit** is a folder that is moved, coloured or
listed as one thing and never reorganised inside; the **skip list** is what no skill
touches or even proposes.

## Units (whole, never rearranged inside)

A folder is a unit when any of these is directly inside it:

| Marker | Means |
|---|---|
| `.git\` | a git repository |
| `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `.claude\` | a workspace an agent works in; moving its parts breaks the project |
| `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `*.sln`, `*.csproj`, `Makefile` | a build root |
| `.obsidian\` | an Obsidian vault |
| a cloud root (`OneDrive`, `Google Drive`, `Dropbox`, as detected by the inventory) | sync would break |
| a `desktop.ini` with an icon this repo did not write | another tool owns its look |

What a skill may do with a unit: move it as a whole (organize-pc, after a yes), colour or
tag the unit folder itself (auto-color, folder-colors), list it. What no skill does: move,
rename or regroup anything inside it, or write `00_README.md` into it. tidy-folder
declines a unit outright and says why.

`Get-PcInventory.ps1` reports `isGitRepo`, `isWorkspace` and `isCloudRoot` per folder so
the check is one lookup, not a guess.

## Skip list (never in a proposal)

`C:\Windows`, `Program Files`, `Program Files (x86)`, `ProgramData`, `AppData`,
`$RECYCLE.BIN`, `System Volume Information`, `node_modules`, `.git` internals, hidden
system items, and the Windows library stubs inside Documents (`My Music`, `My Pictures`,
`My Videos`).
