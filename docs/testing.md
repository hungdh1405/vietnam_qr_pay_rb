# Testing Guide

## Purpose

This repository is small, but the tests play an important role because QR payload compatibility depends on exact string output.

Even a tiny change in:

- field ordering
- field omission
- nested provider data
- CRC calculation

can change the final QR string.

## Test Files

### `test/qr_pay_test.rb`

Covers:

- VietQR decode/build round-trip
- VNPayQR decode/build round-trip
- static and dynamic VietQR generation
- MoMo and ZaloPay compatibility examples
- EVN QR and AirPay-style payload support
- CRC validation rules
- extension field handling

### `test/catalog_test.rb`

Covers:

- generated bank catalog counts
- key lookups
- bank app lookup behavior
- selected catalog field expectations

## Commands

Preferred:

```bash
make test
```

Equivalent:

```bash
bundle exec rake test
```

## When to Add Tests

Add or update tests whenever you change:

- `QRPay#build`
- `QRPay#parse`
- any provider-specific behavior
- any field ID mapping
- any generated catalog transformation

## What to Check When a Test Fails

### Payload mismatch

Usually means one of these changed:

- field order
- a field was omitted
- a field length changed
- the nested provider block changed
- CRC was generated from a different prefix

### CRC mismatch

Check:

- whether the payload includes `6304` before CRC generation
- whether the serialized prefix is exactly correct
- whether any comment or refactor changed concatenation order

### Catalog mismatch

Check:

- upstream reference content
- generator parsing rules
- manual edits in generated files

## Recommended Verification Flow

For normal code changes:

```bash
make test
make build
```

For catalog changes:

```bash
make sync-catalog
make test
make build
```
