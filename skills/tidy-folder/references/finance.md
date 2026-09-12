# Finance profile

Strict rules for a folder that holds a business's financial records. Applies when the
folder's Folder Colors category is `Finance`, or the user says the folder is finance. One
structure, one name pattern, and the reasons: the records stay audit-ready for the whole
retention period, everything sorts by date, and a ledger can be derived from the tree and
the names alone. Sources for every rule are in `sources.md`.

## Jurisdiction first

Nothing is proposed before these are answered, once per finance folder:

1. In which country is this business tax-resident?
2. Entity type: sole trader / freelancer, partnership, company?
3. Registered for VAT (or sales tax) and on which filing period (month, quarter, year)?
4. Does an accountant or bookkeeper receive the records, and how?
5. Which year does the folder start from?

The answers go into the folder's `00_README.md` frontmatter:

```yaml
jurisdiction: NL          # a file in jurisdictions\ (nl.md), or generic
entity: sole-trader
vat_registered: true
vat_period: quarter       # month | quarter | year
retention_years: 7
accountant: none          # or how records are handed over
```

Rules that depend on the country (retention, VAT period naming, mandatory invoice fields,
original-form rule) are read from `jurisdictions\<code>.md`. When no file exists for the
country, `jurisdictions\generic.md` lists what to look up and the profile asks the user
for those values instead of assuming them. Two businesses in two countries can live on one
machine: each finance folder carries its own frontmatter.

## Structure

```
<Finance folder>\
  00_README.md                  rules and frontmatter (this profile writes it)
  00_Master\                    evergreen: registration, VAT id letter, insurance,
                                policies, contract templates, bank account agreements
  2026\
    01_Invoices_Received\       purchase invoices (what you owe)
    02_Invoices_Sent\           sales invoices (what you are owed)
    03_Receipts\                small purchases without an invoice number
    04_Bank_Statements\
    05_Tax_Filings\             VAT returns and tax letters; period in the file name
    06_Contracts\
    07_Correspondence\          letters from the tax office, bank, accountant
    08_Payroll_or_Time\         payslips, time records (omit when there are none)
  2025\  ...
```

- One folder per year, because retention runs per year and an audit asks for a year.
- Inside a year, the subfolder is the document type (paperless-ngx's `document_type`);
  the party (correspondent) lives in the file name, not in a folder, so a supplier with
  one invoice does not earn a folder.
- `00_Master` holds what does not belong to a year. Never duplicate a master document into
  a year folder; link to it from the README if needed.
- Depth three at most: `2026\01_Invoices_Received\<file>`.
- Nothing is deleted. A wrong year is a move; a superseded document goes to
  `<year>\09_Superseded\` only if the user wants it kept out of sight.

## Names

`YYYY-MM-DD_<Type>_<Party>_<Reference>.<ext>`

- `YYYY-MM-DD`: the document's own date (invoice date, statement date, filing date),
  never the download date.
- `<Type>` from this list only: `Invoice`, `Receipt`, `Statement`, `VAT`, `Tax`,
  `Contract`, `Letter`, `Payslip`.
- `<Party>`: one spelling per party, no spaces (`Acme`, `ExampleBank`,
  `Belastingdienst`); the README keeps the list. For sales invoices the party is the
  customer.
- `<Reference>`: the invoice or statement number as printed. A receipt without a number
  carries the amount with a dot (`84.20`). A VAT filing carries its period (`2026-Q1`,
  `2026-03` for monthly filers).
- Examples: `2026-02-04_Invoice_Acme_2026-0142.pdf`,
  `2026-04-02_VAT_Belastingdienst_2026-Q1.pdf`, `2026-06-14_Receipt_HardwareStore_84.20.pdf`,
  `2026-01-31_Statement_ExampleBank_2026-01.pdf`.
- No spaces or `:\/?*"<>|`; collisions get `_01`; a `.pdf.pdf` loses one `.pdf`.

## Filing an unnamed document

For each PDF or image dropped into the folder (or its inbox):

1. Read the document itself. Take the date, the issuing party, the number or period, the
   total, and the currency from what is printed. These are invoice2data's fields
   (issuer, date, invoice_number, amount, currency); a Factur-X PDF carries them in XML.
2. Decide the type: an invoice addressed to the business is `Invoice` into
   `01_Invoices_Received`; one issued by the business is `Invoice` into
   `02_Invoices_Sent`; a till receipt is `Receipt`; a bank document is `Statement`; a
   letter from the tax office about VAT is `VAT`, other tax letters `Tax`.
3. Build the name and the destination (`<year of the date>\<subfolder>\<name>`).
4. Anything the document does not state (no date, no party) is a row marked "needs you",
   not a guess.
5. All rows go into one table and one `Move-Tracked.ps1` batch. Originals are moved, not
   copied: the moved file is the original, in its original form.

## Outgoing invoices

When the folder holds sales invoices, the README carries the jurisdiction's mandatory
invoice elements (from `jurisdictions\<code>.md`) and the numbering rule; the skill
checks a new sales invoice's file name against the sequence it sees and flags a gap or a
repeat.

## What the README says

Frontmatter as above; the structure; the name pattern with three examples; the party
spelling list; the jurisdiction rules in force (retention, VAT period, original-form
rule); where the accountant gets the records; and the sentence "files dropped in the
folder root get filed by tidy-folder", so the folder root doubles as the inbox.
