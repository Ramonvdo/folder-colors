# Sources

What was read for the finance profile, on 2026-09-12, and what each contributed. Chosen
through an expert-skill pick-list; "search-level" marks a source seen only in results,
not fetched. Re-research map: when a rule below is questioned, start at its source.

## Canonical (rules)

- **Belastingdienst, "Uw facturen bewaren"**
  belastingdienst.nl/wps/wcm/connect/bldcontentnl/belastingdienst/zakelijk/btw/administratie_bijhouden/facturen_maken/uw_facturen_bewaren
  Fetched. Contributed: 7-year retention, 10 for real estate and EU schemes; digital stays
  digital; scan may replace paper only when complete and faithful; "controleerbaar".
- **Belastingdienst, "Factuureisen"**
  belastingdienst.nl/wps/wcm/connect/bldcontentnl/belastingdienst/zakelijk/btw/administratie_bijhouden/facturen_maken/factuureisen/factuureisen
  Fetched. Contributed: the 11 mandatory invoice elements and the consecutive, unique
  numbering rule; hence the reference in every sales-invoice file name.
- **Belastingdienst, "Aangiftetijdvak voor de btw"**
  belastingdienst.nl/wps/wcm/connect/nl/btw/content/wijziging-aangiftetijdvak-btw
  Fetched. Contributed: quarterly by default, monthly when imposed, yearly under the
  threshold; period naming of filing files. The deadline (last day of the following
  month) is search-level only, from secondary sites, and marked unverified in `nl.md`.

## Implementations (vocabulary and schema)

- **paperless-ngx, `docs/advanced_usage.md`** (github.com/paperless-ngx/paperless-ngx,
  45k stars, GPL-3.0, active). Fetched from the repository.
  Contributed: year / correspondent / document type as the filing vocabulary, `_01`
  collision suffixes, illegal characters replaced. Not a dependency.
- **invoice2data README** (github.com/invoice-x/invoice2data, 2.2k stars, MIT, active).
  Fetched. Contributed: the extraction schema (issuer, date, invoice_number, amount,
  currency) the file name encodes; "template per recurring vendor" as an idea. Not a
  dependency: Claude reads the PDF.
- **beancount, options: `documents`** (beancount.io/docs/Basics/options-configuration;
  github.com/beancount/beancount, 6k stars, GPL-2.0). Fetched.
  Contributed: date-first `YYYY-MM-DD` names, folder = account, loose files at the root
  are ignored; the reason a ledger can later be derived from the tree.

## Baseline

- **ComposioHQ/awesome-claude-skills, `invoice-organizer/SKILL.md`** (index repo, 74.9k
  stars, no licence file). Fetched.
  Contributed: the "flag for manual review when data is missing" fallback, kept. Differed
  from on purpose: it copies files, uses spaces and dashes in names, sorts by vendor or
  category folders, and carries no jurisdiction rules; this profile moves with a log, uses
  underscores, files by year and type, and asks the jurisdiction first.

## Working knowledge

- **Cash Workspace, "Receipt Naming & Filing Convention Guide"**
  cashworkspace.com/expense-receipt-naming-convention-guide. Fetched; the page calls
  itself organising guidance, not accounting advice.
  Contributed two rules: one spelling per vendor; a receipt without a number carries the
  amount.

## Parked for the bookkeeping skill (not used here)

- **EN 16931 / Peppol BIS / Factur-X field model**: search-level (e-invoice.be mapper,
  validatefin.com guide, github.com/eukittoh22/einvoice-examples). Would give the
  canonical field names and a no-OCR path for PDFs that carry XML.
- **openaccountant/skills, `business/stripe-import/SKILL.md`** (68 stars, MIT). Fetched.
  Charges and fees as separate lines, payouts skipped, dedupe on charge id. Its tax
  skills are US-only.
- **ashenwolf/gmail-invoice-importer README** (MIT). Fetched. Gmail label as trigger,
  archive state as dedupe, `YYYY/YYYY-MM` filing; needs a Google Cloud service account
  and a Gemini key.

## Rejected

- Johnny.Decimal "15.04 Small Business System": paid, outline not public.
- Renamed.to and similar naming guides: nothing beyond the sources above.
- KVK record-keeping page: the URL found returned 404.
