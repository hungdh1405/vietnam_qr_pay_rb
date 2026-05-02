# Architecture

## Overview

`VietnamQrPay` is a small Ruby payment QR library. The gem is intentionally split into two parts:

- Hand-written QR logic for parsing, building, and CRC validation
- Generated catalog data copied from the bundled source constants

This split matters because the QR logic changes rarely, while the bank and app catalog can drift over time as the upstream reference is updated.

## Runtime Structure

The main runtime entrypoint is `VietnamQrPay::QRPay`.

It is responsible for:

- Parsing a QR payload into mutable Ruby structs
- Preserving unknown provider data so decode/build round-trips stay lossless
- Rebuilding a canonical TLV payload
- Regenerating the final CRC field

Supporting objects under `lib/vietnam_qr_pay/models/` are intentionally simple `Struct` types:

- `Provider`
- `Merchant`
- `Consumer`
- `AdditionalData`
- `Bank`
- `BankApp`

## Payload Model

The gem treats the QR string as a TLV payload:

- `id`: 2 characters
- `length`: 2 characters
- `value`: `length` characters

The parser walks the payload recursively by repeatedly slicing the next field.

Important behavior:

- CRC is validated before any field parsing is trusted
- Unknown provider payloads are preserved instead of rejected
- EMVCo extension fields `65-79` and unreserved fields `80-99` are retained for round-trip safety

## Provider Handling

The builder has provider-specific branches because VietQR and VNPayQR do not store their key fields the same way.

VietQR:

- Provider GUID: `A000000727`
- Consumer data contains bank BIN and account/card number
- `init_method` is `11` for static QR and `12` when amount is fixed

VNPayQR:

- Provider GUID: `A000000775`
- Provider data stores the merchant identifier directly

Other providers:

- The gem keeps the raw provider GUID and data
- The object can still be rebuilt if the payload parses and CRC is valid

## Generated Catalog

The files under `lib/vietnam_qr_pay/catalog/` are generated from:

- `references/source/constants/bank-key.ts`
- `references/source/constants/bank-code.ts`
- `references/source/constants/banks.ts`
- `references/source/constants/bank-apps.ts`

Do not edit those generated Ruby files directly. Update the source sync script and regenerate instead.

## Related Guides

- [Implementation Guide](implementation-guide.md)
- [Testing Guide](testing.md)
- [Catalog Sync](catalog-sync.md)
- [Releasing](releasing.md)
