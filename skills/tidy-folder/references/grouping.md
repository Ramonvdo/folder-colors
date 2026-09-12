# Grouping and naming rules

How tidy-folder turns a folder of loose files into a few subfolders and consistent names.
The finance profile (`finance.md`) overrides these when the folder is finance.

## Grouping

- **Earn a subfolder.** A dozen files that belong together earn one; three do not. At
  most five new subfolders per run; a folder that needs more is two folders.
- **Topic before type.** When names carry a topic (a client, a project code, a trip, a
  course), group by topic (`Acme`, `Website redesign`, `Lisbon 2026`). Group by type
  (`Images`, `Screenshots`, `PDFs`, `Installers`, `Archives`) only when no topic shows.
- **Screenshots are their own thing.** `Screenshot 2026-09-01...`, `Schermafbeelding...`,
  `Capture...` go to `Screenshots`, never to `Images`.
- **Installers and archives** go to `Installers` and `Archives`; both are candidates for
  the archive later, say so in the table.
- **Stays loose:** `00_README.md`, `README.md`, `CLAUDE.md`, index files, and any file
  the user names as "keep here".
- **Existing subfolders** are used before new ones are made. A protected unit
  (`..\..\shared\protected-units.md`) is neither opened nor moved; it is listed and left.
- **Names of new subfolders:** short, Title Case, no numbering inside an ordinary folder
  (numbering belongs to the areas of organize-pc). Existing naming style in the folder
  wins over these defaults.
- **Overlap check:** for each pair of proposed subfolders, name a file that could go to
  either and write the tie-break into the table.
- **Duplicates by name** (`report (1).pdf` next to `report.pdf`) are listed side by side
  and left; deciding is the user's.

## Naming

Normalisation is offered as its own batch, after grouping, so it can be undone on its own.

- Pattern: `YYYY-MM-DD_<Type>_<Name>` plus the extension. The date is the document's own
  date (from the content when Claude reads it, else a date in the file name, else the
  file's last-write date, in that order; the table says which was used).
- Types for ordinary folders: `Doc`, `Sheet`, `Deck`, `Image`, `Screenshot`, `Video`,
  `Audio`, `Archive`, `Installer`, `Note`, `Contract`, `Letter`. Finance types live in
  `finance.md`.
- `<Name>`: the topic in Title Case without spaces (`WebsiteRedesign`), or the original
  base name with spaces turned into underscores when nothing better is known. Keep the
  original name recoverable: the move log stores it.
- No spaces, no `:\/?*"<>|`, no trailing dots; collisions get `_01`, `_02`.
- Files already matching the pattern are left alone (`normalised` in the profile).
- Double extensions (`file.pdf.pdf`) lose the extra one in the same batch.
