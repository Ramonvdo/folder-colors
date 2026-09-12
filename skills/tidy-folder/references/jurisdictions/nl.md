# Jurisdiction: Netherlands (NL)

The worked example. Every rule cites the Belastingdienst page it was read from on
2026-09-12 (URLs in `..\sources.md`). Rules change; when a date here is older than a year,
re-check the page before relying on it.

## Retention

- Keep the administration for **7 years** ("U bent verplicht uw administratie 7 jaar te
  bewaren"). Invoices about real estate: **10 years**. Supplies under the EU Union or
  Import schemes: 10 years. Source: "Uw facturen bewaren".
- Keep invoices **in the form you sent or received them**: a digital invoice stays digital
  ("Digitale facturen drukt u dus niet af, maar slaat u digitaal op"). A paper original may
  be replaced by a scan only if the scan is a complete and faithful copy; the same 7 or 10
  years then apply to the scan. Records must be checkable within a reasonable time
  ("binnen een redelijke termijn controleerbaar"). Consequence for filing: the PDF that
  arrived by mail is the record; the folder holds it unchanged, only renamed.

## VAT (btw)

- Returns are usually filed **per quarter** ("Btw-aangifte doet u meestal per kwartaal").
  Monthly can be imposed after late filing or payment; yearly is possible for small
  sole traders and partnerships of natural persons under a threshold (EUR 1,883 of VAT a
  year at the time of reading). Source: "Aangiftetijdvak voor de btw".
- The exact filing and payment dates come with the yearly letter and in Mijn
  Belastingdienst Zakelijk. Secondary sources state the last day of the month after the
  quarter (30 April, 31 July, 31 October, 31 January); treat that as unverified until read
  on the Belastingdienst page.
- Filing files are named by period: `2026-Q1`, or `2026-03` for monthly filers.

## Mandatory elements of a sales invoice (factuureisen)

From "Factuureisen"; a sales invoice must show:

1. your full name and the customer's;
2. your full address and the customer's (a real business address, not only a P.O. box);
3. your VAT identification number (starting with NL);
4. your KVK number, when registered;
5. the invoice date;
6. an invoice number: **consecutive numbers, one or more series, each number used once**
   ("Gebruik opeenvolgende nummers voor uw facturen, met 1 of meer reeksen. Elk
   factuurnummer mag maar 1 keer voorkomen");
7. the quantity and nature of the goods or services;
8. the date of delivery, or of a prepayment;
9. the amount excluding VAT, split per rate when more than one applies;
10. the VAT rate;
11. the VAT amount.

Consequence for naming: the invoice number is the `<Reference>` of every sales invoice,
and the skill flags a gap or a repeat in the sequence it sees in `02_Invoices_Sent`.

## Frontmatter defaults for NL

```yaml
jurisdiction: NL
retention_years: 7
vat_period: quarter
```
