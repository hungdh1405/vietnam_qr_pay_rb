# Catalog Sync

## Purpose

The bank catalog and bank app metadata are copied from the bundled upstream JavaScript reference so the Ruby gem keeps the same public identifiers and compatibility data.

## Source of Truth

Upstream reference directory:

```text
references/vietnam-qr-pay-javascript/src/constants/
```

Ruby generated output:

```text
lib/vietnam_qr_pay/catalog/
```

## Regenerate

Run:

```bash
ruby script/generate_catalog.rb
```

This regenerates:

- `bank_keys.rb`
- `bank_codes.rb`
- `banks.rb`
- `bank_apps.rb`

## Editing Rule

If the generated output is wrong:

- Fix `script/generate_catalog.rb`
- Re-run the generator
- Re-run tests

Do not hand-edit generated catalog files, because those changes will be lost the next time the sync script runs.
