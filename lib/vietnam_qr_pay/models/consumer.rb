# frozen_string_literal: true

module VietnamQrPay
  # Consumer account information stored inside a VietQR provider block.
  Consumer = Struct.new(
    :bank_bin,
    :bank_number,
    keyword_init: true
  )
end
