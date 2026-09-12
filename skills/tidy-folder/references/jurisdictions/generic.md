# Jurisdiction: generic (any country without its own file)

The finance profile assumes nothing about a country it has no file for. Ask the user for
these values, write them into the folder's `00_README.md` frontmatter, and cite where the
user got them (a tax-authority page is the right source; an accountant's word is fine
when written down).

| Value | Ask | Frontmatter key |
|---|---|---|
| Retention period | "How many years must business records be kept where you are taxed?" | `retention_years` |
| Original-form rule | "May a scanned paper invoice replace the original, and must a digital invoice stay digital?" | `original_form` (`keep-original` / `scan-allowed`) |
| VAT or sales tax | "Are you registered, and is the return monthly, quarterly or yearly?" | `vat_registered`, `vat_period` |
| Invoice requirements | "Which elements must your sales invoices show, and must numbers be consecutive?" | `invoice_rules` (free text or a link) |
| Accountant hand-over | "Does someone receive the records, and in what form?" | `accountant` |

Until the answers are in, the profile still files and names documents (the structure and
the name pattern do not depend on the country), but it writes `retention_years: unknown`
rather than a guess, and it does not check invoice sequences.

To add a country, copy `nl.md`, replace every rule with the local one, cite each source
with the date it was read, and name the file by the ISO country code (`de.md`, `be.md`).
