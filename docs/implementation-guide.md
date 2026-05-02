# Implementation Guide

## Purpose

This guide explains how the handwritten Ruby implementation works so future changes can be made safely without rediscovering the logic from scratch.

Use this document when you need to:

- add support for a new QR provider variant
- change how a field is parsed or built
- debug why a generated payload does not match an expected QR string
- understand where to update tests after a behavior change

## Main Files

### Entrypoint

- `lib/vietnam_qr_pay.rb`

Loads the library and exposes convenience helpers:

- `VietnamQrPay.bank(key)`
- `VietnamQrPay.bank_app(key)`

### Core QR Logic

- `lib/vietnam_qr_pay/qr_pay.rb`

This is the most important file in the repository.

Responsibilities:

- parsing QR payload strings
- validating CRC before trusting payload content
- storing parsed values in mutable Ruby structs
- rebuilding payloads in canonical field order
- preserving unknown extension data for round-trip safety

### Constants

- `lib/vietnam_qr_pay/constants.rb`

Defines:

- provider names and GUIDs
- top-level field IDs
- nested provider field IDs
- VietQR service codes
- additional data field IDs
- EMVCo and unreserved extension field ranges

### CRC

- `lib/vietnam_qr_pay/crc16.rb`

Implements CRC16-CCITT over UTF-8 bytes.

### Models

- `lib/vietnam_qr_pay/models/*.rb`

These are simple data containers. They intentionally do not contain business logic.

### Generated Catalog

- `lib/vietnam_qr_pay/catalog/*.rb`

Generated from the bundled source constants. Do not edit by hand.

### Generator

- `script/generate_catalog.rb`

Transforms the bundled source constants into Ruby constants and structs.

### Tests

- `test/qr_pay_test.rb`
- `test/catalog_test.rb`

These verify payload compatibility and catalog surface behavior.

## QRPay Object Lifecycle

### 1. Create

There are two common ways to create a `QRPay` instance:

Decode an existing payload:

```ruby
qr = VietnamQrPay::QRPay.new(payload)
```

Build a new payload from helpers:

```ruby
qr = VietnamQrPay::QRPay.init_viet_qr(...)
qr = VietnamQrPay::QRPay.init_vnpay_qr(...)
```

### 2. Parse

When `QRPay.new(payload)` receives content:

1. `initialize` creates empty containers
2. `parse(content)` resets the state again
3. CRC is verified first
4. only then does field parsing begin

This order is important. The gem does not trust field content from an invalid QR string.

### 3. Mutate

After decoding or building, callers may change fields directly:

```ruby
qr.amount = "150000"
qr.additional_data.purpose = "Thanh toan don hang 123"
qr.set_unreserved_field("80", "046")
```

### 4. Build

`build` serializes all known fields, appends the `63` CRC marker, then generates the final 4-character CRC suffix.

## Parse Flow

### `parse`

Method location:

- `lib/vietnam_qr_pay/qr_pay.rb`

Logic:

1. reset all state
2. reject `nil` or too-short input
3. validate CRC
4. call `parse_root_content`

### `parse_root_content`

This is the top-level TLV parser loop.

It reads one field at a time using `slice_content`, then dispatches by field ID.

Examples:

- `00` -> version
- `01` -> init method
- `26` / `38` -> provider template
- `62` -> additional data
- `63` -> CRC

Unknown extension fields are not discarded:

- `65-79` are stored in `evmco`
- `80-99` are stored in `unreserved`

That behavior is important because many real-world provider variants add fields the gem does not formally model.

### `parse_provider_info`

This parses the nested provider template.

Provider-specific behavior:

- if GUID is VietQR, nested consumer data is parsed into `bank_bin` and `bank_number`
- if GUID is VNPayQR, provider data becomes `merchant.id`
- otherwise, raw provider data is retained

### `parse_vietqr_consumer`

This parses the inner VietQR consumer block:

- `00` -> bank BIN
- `01` -> account/card number

### `parse_additional_data`

This parses field `62`, including:

- bill number
- mobile number
- store
- loyalty number
- reference
- customer label
- terminal
- purpose
- additional consumer data request

## Build Flow

### `build`

`build` works in this order:

1. compute provider-specific nested data
2. compute nested provider template
3. compute nested additional data block
4. serialize root-level fields
5. serialize extension fields
6. append `6304`
7. compute CRC over the full prefix

The builder uses explicit array joins instead of long chained concatenation.

Why that matters:

- it is easier to read and change
- comments do not accidentally break expression chaining
- field ordering stays explicit

### `field_data`

This helper serializes one TLV field.

Rules:

- field IDs must be exactly 2 characters
- blank values are omitted
- field length is formatted as 2 digits

Example:

```ruby
field_data("54", "150000")
# => "5406150000"
```

### `build_fields`

This serializes extension field hashes in sorted order.

That ordering is important for stable output and deterministic CRC generation.

## Provider-Specific Rules

## VietQR

Helper:

- `QRPay.init_viet_qr`

Important rules:

- defaults `provider.guid` to `A000000727`
- defaults service to `QRIBFTTA`
- uses init method `11` when no amount is present
- uses init method `12` when amount is present

If you need to add another VietQR-specific field rule, start in:

- `init_viet_qr`
- `build`
- `parse_provider_info`
- `parse_vietqr_consumer`

## VNPayQR

Helper:

- `QRPay.init_vnpay_qr`

Important rules:

- defaults `provider.guid` to `A000000775`
- stores merchant identifier directly in provider data
- stores store/terminal/purpose in additional data field `62`

If you need to change VNPayQR behavior, start in:

- `init_vnpay_qr`
- `build`
- `parse_provider_info`

## Unknown Providers

The gem intentionally supports partial decoding for unknown providers.

This is done by:

- validating CRC
- preserving provider GUID and provider data
- preserving extension fields

This makes `decode -> inspect -> rebuild` possible even when the gem does not yet have a full domain model for that provider.

## CRC Logic

### Verification

`verify_crc(content)`:

- removes the last 4 characters from the payload
- uppercases the trailing CRC from the original string
- recomputes the CRC from the prefix
- compares the two values

This means lowercase CRC input is accepted as long as the value is correct.

### Generation

`gen_crc_code(content)` returns:

- uppercase
- 4 characters
- zero-padded

## Extension Fields

### EVMCo Fields

Range:

- `65` to `79`

Storage:

- `qr.evmco`

Setter:

```ruby
qr.set_evmco_field("65", "EXTRA")
```

### Unreserved Fields

Range:

- `80` to `99`

Storage:

- `qr.unreserved`

Setter:

```ruby
qr.set_unreserved_field("80", "046")
```

MoMo depends on this behavior for its provider-specific field.

## Common Change Recipes

### Add a New Top-Level Field

1. add the field ID to `constants.rb`
2. add an accessor to `QRPay`
3. update `parse_root_content`
4. update `build`
5. add tests for decode and build

### Add a New Additional Data Field

1. add the field ID in `AdditionalDataID`
2. add a member to `AdditionalData`
3. update `parse_additional_data`
4. update `build`
5. add tests

### Add a New Provider Variant

1. define provider constants if needed
2. decide whether it fits existing provider parsing or needs a new branch
3. update `build`
4. update `parse_provider_info`
5. add fixtures to `test/qr_pay_test.rb`

### Change the Bank Catalog

1. update upstream reference under `references/`
2. run `ruby script/generate_catalog.rb`
3. run tests
4. do not hand-edit generated catalog files

## Test Mapping

### `test/qr_pay_test.rb`

Use this file when changing:

- parse logic
- build logic
- CRC behavior
- provider behavior
- extension field handling

### `test/catalog_test.rb`

Use this file when changing:

- generated bank catalog shape
- convenience helpers
- bank app metadata surface

## Safe Editing Rules

- Prefer changing handwritten files under `lib/vietnam_qr_pay/` before touching generated output.
- Never edit `lib/vietnam_qr_pay/catalog/*.rb` manually.
- If a QR payload changes unexpectedly, compare both the serialized field order and the CRC suffix.
- After every behavior change, run:

```bash
make test
make build
```
