# frozen_string_literal: true

require_relative "lib/vietnam_qr_pay/version"

Gem::Specification.new do |spec|
  spec.name = "vietnam_qr_pay"
  spec.version = VietnamQrPay::VERSION
  spec.authors = ["Do Huy Hung"]
  spec.email = ["hungdh@doxanh.dev"]

  spec.summary = "Encode and decode Vietnamese payment QR codes for VietQR, VNPayQR, MoMo, and ZaloPay."
  spec.description = <<~TEXT.strip
    VietnamQrPay is a dependency-free Ruby implementation of Vietnamese payment QR standards.
    It supports building and parsing VietQR and VNPayQR payloads, decoding related provider formats,
    and ships the bank catalog exposed by the original vietnam-qr-pay JavaScript library.
  TEXT
  spec.homepage = "https://github.com/hungdh1405/vietnam_qr_pay_rb"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0"

  spec.metadata = {
    "bug_tracker_uri" => "https://github.com/hungdh1405/vietnam_qr_pay_rb/issues",
    "changelog_uri" => "https://github.com/hungdh1405/vietnam_qr_pay_rb/blob/main/CHANGELOG.md",
    "documentation_uri" => "https://github.com/hungdh1405/vietnam_qr_pay_rb#readme",
    "homepage_uri" => spec.homepage,
    "rubygems_mfa_required" => "true",
    "source_code_uri" => "https://github.com/hungdh1405/vietnam_qr_pay_rb"
  }

  # Include repository docs so the packaged gem carries architecture and release notes too.
  spec.files = Dir.chdir(__dir__) do
    Dir.glob(%w[CHANGELOG.md LICENSE README.md docs/**/* lib/**/*])
  end
  spec.require_paths = ["lib"]

  spec.add_development_dependency "minitest", "~> 6.0"
  spec.add_development_dependency "rake", "~> 13.4"
end
