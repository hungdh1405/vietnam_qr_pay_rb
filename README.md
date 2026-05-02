# VietnamQrPay

`VietnamQrPay` is a dependency-free Ruby implementation of Vietnamese payment QR standards.

It ports the core behavior of the original [`xuannghia/vietnam-qr-pay`](https://github.com/xuannghia/vietnam-qr-pay) JavaScript library and provides a Ruby-idiomatic API for:

- Encoding VietQR payloads
- Encoding VNPayQR payloads
- Decoding VietQR, VNPayQR, and related EMVCo-style QR payloads
- Working with the upstream bank catalog and supported bank app metadata
- Building MoMo and ZaloPay receive QR payloads that are represented as VietQR over BVBank accounts

## Features

- No runtime dependencies
- Pure Ruby CRC16-CCITT implementation
- Ruby-style module and method naming
- Public bank constants ported from the JavaScript reference
- Test coverage based on the upstream fixtures and expected payloads
- Ready-to-publish gem metadata for RubyGems

Current release in this repository: `0.1.1`

## Documentation

- [Architecture](docs/architecture.md)
- [Implementation Guide](docs/implementation-guide.md)
- [Testing Guide](docs/testing.md)
- [Catalog Sync](docs/catalog-sync.md)
- [Releasing](docs/releasing.md)

## Installation

Install from RubyGems:

```bash
gem install vietnam_qr_pay
```

Or add it to your `Gemfile`:

```ruby
gem "vietnam_qr_pay"
```

Then require it:

```ruby
require "vietnam_qr_pay"
```

## Quick Start

### Build a static VietQR

```ruby
require "vietnam_qr_pay"

qr = VietnamQrPay::QRPay.init_viet_qr(
  bank_bin: VietnamQrPay::BanksObject[:acb].bin,
  bank_number: "257678859"
)

qr.build
# => "00020101021138530010A0000007270123000697041601092576788590208QRIBFTTA53037045802VN6304AE9F"
```

### Build a dynamic VietQR

```ruby
require "vietnam_qr_pay"

qr = VietnamQrPay::QRPay.init_viet_qr(
  bank_bin: VietnamQrPay::BanksObject[:acb].bin,
  bank_number: "257678859",
  amount: "10000",
  purpose: "Chuyen tien"
)

qr.build
# => "00020101021238530010A0000007270123000697041601092576788590208QRIBFTTA53037045405100005802VN62150811Chuyen tien630453E6"
```

### Build a VNPayQR payload

```ruby
require "vietnam_qr_pay"

qr = VietnamQrPay::QRPay.init_vnpay_qr(
  merchant_id: "0102154778",
  merchant_name: "TUGIACOMPANY",
  store: "TU GIA COMPUTER",
  terminal: "TUGIACO1"
)

qr.build
# => "00020101021126280010A0000007750110010215477853037045802VN5912TUGIACOMPANY62310315TU GIA COMPUTER0708TUGIACO16304DF44"
```

### Decode a QR payload

```ruby
require "vietnam_qr_pay"

payload = "00020101021238530010A0000007270123000697041601092576788590208QRIBFTTA5303704540410005802VN62150811Chuyen tien6304BBB8"
qr = VietnamQrPay::QRPay.new(payload)

qr.valid?                       # => true
qr.provider.name               # => "VIETQR"
qr.consumer.bank_bin           # => "970416"
qr.consumer.bank_number        # => "257678859"
qr.amount                      # => "1000"
qr.additional_data.purpose     # => "Chuyen tien"
```

## Supported Payment Flows

### VietQR

Use `VietnamQrPay::QRPay.init_viet_qr` for bank-account or card-based VietQR payloads.

```ruby
qr = VietnamQrPay::QRPay.init_viet_qr(
  bank_bin: VietnamQrPay::BanksObject[:acb].bin,
  bank_number: "257678859",
  service: VietnamQrPay::VietQRService::BY_ACCOUNT_NUMBER
)
```

### MoMo and ZaloPay receive QR

The JavaScript reference treats these as VietQR payloads routed through BVBank. This gem keeps the same model.

MoMo example:

```ruby
account_number = "99MM24011M34875080"

qr = VietnamQrPay::QRPay.init_viet_qr(
  bank_bin: VietnamQrPay::BanksObject[:banviet].bin,
  bank_number: account_number
)

qr.additional_data.reference = "MOMOW2W#{account_number[10..]}"
qr.set_unreserved_field("80", "046")

qr.build
# => "00020101021138620010A00000072701320006970454011899MM24011M348750800208QRIBFTTA53037045802VN62190515MOMOW2W3487508080030466304EBC8"
```

ZaloPay example:

```ruby
qr = VietnamQrPay::QRPay.init_viet_qr(
  bank_bin: VietnamQrPay::BanksObject[:banviet].bin,
  bank_number: "99ZP24009M07248267"
)

qr.build
# => "00020101021138620010A00000072701320006970454011899ZP24009M072482670208QRIBFTTA53037045802VN6304073C"
```

### Generic decode support

`VietnamQrPay::QRPay.new(payload)` will also decode provider variants such as AirPay and non-standard EMVCo-style payloads, as long as the CRC is valid. Unknown providers keep their raw provider GUID and provider data so the payload can still be inspected or rebuilt.

## Public API

### Main class

`VietnamQrPay::QRPay`

- `valid?` / `is_valid`
- `build`
- `parse`
- `set_evmco_field`
- `set_unreserved_field`
- `.init_viet_qr`
- `.init_vnpay_qr`
- `.verify_crc`
- `.gen_crc_code`

### Data objects

- `VietnamQrPay::Provider`
- `VietnamQrPay::Merchant`
- `VietnamQrPay::Consumer`
- `VietnamQrPay::AdditionalData`
- `VietnamQrPay::Bank`
- `VietnamQrPay::BankApp`

### Catalog constants

- `VietnamQrPay::BankKey`
- `VietnamQrPay::BankCode`
- `VietnamQrPay::BanksObject`
- `VietnamQrPay::Banks`
- `VietnamQrPay::BankApps`
- `VietnamQrPay.bank(:acb)`
- `VietnamQrPay.bank_app(:acb)`

## Bank Lookup Helpers

The generated catalog is available both as constants and convenience helpers:

```ruby
bank = VietnamQrPay.bank(:vietinbank)
bank.bin
# => "970415"

app = VietnamQrPay.bank_app(:vietinbank)
app&.package_id
# => "com.vietinbank.ipay"
```

## Module Naming and Folder Structure

The gem uses standard Ruby naming:

- Top-level namespace: `VietnamQrPay`
- Main QR class: `VietnamQrPay::QRPay`
- Constant modules: `VietnamQrPay::BankKey`, `VietnamQrPay::BankCode`, `VietnamQrPay::QRProvider`
- Mutable QR payload objects: `Provider`, `Merchant`, `Consumer`, `AdditionalData`

The project layout is split by responsibility:

```text
lib/
  vietnam_qr_pay.rb
  vietnam_qr_pay/
    version.rb
    constants.rb
    crc16.rb
    qr_pay.rb
    catalog.rb
    catalog/
      bank_keys.rb
      bank_codes.rb
      banks.rb
      bank_apps.rb
    models/
      provider.rb
      merchant.rb
      consumer.rb
      additional_data.rb
      bank.rb
      bank_app.rb
script/
  generate_catalog.rb
test/
  *_test.rb
```

`script/generate_catalog.rb` is intentionally kept in the repository so you can re-sync the bank catalog from the upstream JavaScript reference later without hand-editing large constant files.

## Development

Run the test suite:

```bash
bundle exec rake test
```

Build the gem:

```bash
bundle exec rake build
```

Refresh the bank catalog from the bundled JavaScript reference:

```bash
ruby script/generate_catalog.rb
```

The generator expects the upstream JavaScript source to be available at `references/vietnam-qr-pay-javascript`.

For deeper implementation notes and release workflow, see the files under [`docs/`](docs).

## Release Status

The repository is currently prepared for publishing version `0.1.1`.

Recommended pre-push sequence:

```bash
bundle exec rake test
bundle exec rake build
gem push pkg/vietnam_qr_pay-0.1.1.gem
```

If you use the repository `Makefile`, `make publish` computes the gem filename automatically from `lib/vietnam_qr_pay/version.rb`. See [docs/releasing.md](docs/releasing.md) for the `$(GEM_FILE)` explanation.

## Compatibility Notes

- This gem follows the bundled JavaScript reference for payload structure and expected examples.
- The Ruby API is intentionally snake_case instead of camelCase.
- Builder instances created with `init_viet_qr` and `init_vnpay_qr` start in a valid state, which is more natural for Ruby than marking empty objects invalid.
- `set_evmco_field` writes to the EVMCo field set directly.

## Credits

- Original JavaScript library: `xuannghia/vietnam-qr-pay`
- Ruby port and packaging: this repository

## License

Released under the MIT License. See [LICENSE](LICENSE).
