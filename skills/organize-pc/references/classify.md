# Classifying items

How each existing folder or loose file gets a target in the proposal. Apply the rules in
order; the first that decides, decides. Every row of the proposal carries the rule that
placed it, in one line.

1. **Units stay whole.** Everything `..\..\..\shared\protected-units.md` lists: a git
   repository, a workspace with `CLAUDE.md`, `AGENTS.md` or a build root, an Obsidian
   vault, a cloud root, a folder another tool gave an icon. Moved as one item or left in
   place, never rearranged inside, never given a README. The inventory marks them
   (`isGitRepo`, `isWorkspace`, `isCloudRoot`).
2. **Skip list.** The same file's skip list. Those folders are not in the proposal at all.
3. **The folder's own words.** A `README.md`, `CLAUDE.md` or `00_README.md` inside it says
   what it is; believe it over the name.
4. **Name signals.** Client and company names, `invoice`, `receipt`, `tax`, `vat`,
   `contract`, `agreement`, `course`, `book`, `brand`, `logo`, `footage`, `backup`,
   `template`, `old`, `archive`, a year, and their equivalents in the user's language
   (`factuur`, `Rechnung`). The `hints` list of each category in `categories.json` is the
   same idea, in the user's own vocabulary; extend it when the interview reveals words the
   user uses.
5. **Extension clusters** for loose files: documents, images, video, audio, code,
   installers, archives (`Get-PcInventory.ps1` reports them). Installers go to
   `System & Tools` or the archive; archives (`.zip`) are opened in the mind first: a zip of
   client files belongs to the client.
6. **Reference or recurring.** Read-once-keep-forever documents (contracts, reports,
   certificates) and accumulating ones (invoices, statements, exports) live in different
   subfolders even when they share an area. Tax gets a year folder.
7. **Age.** Untouched for more than a year and not a reference document: archive candidate,
   proposed as `99_ARCHIVE\<year of last change>\<name>`.
8. **Duplicates.** `name (1).ext` next to `name.ext`: both stay; the row says so. Deleting
   is the user's job, with the two paths in front of them.
9. **Undecidable.** `00_INBOX`, listed at the end of the proposal with the reason it could
   not be placed. A forced fit costs more than an honest holding pen.

Overlap check before presenting: for every pair of areas, name one item that could go to
either; write the tie-break rule into both READMEs ("client invoices live in
`04_FINANCE\Invoices\<Client>`, not in the client folder").
