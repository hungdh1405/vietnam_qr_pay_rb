# frozen_string_literal: true

module VietnamQrPay
  # Merchant information extracted from VNPayQR-style payloads.
  Merchant = Struct.new(
    :id,
    :name,
    keyword_init: true
  )
end
