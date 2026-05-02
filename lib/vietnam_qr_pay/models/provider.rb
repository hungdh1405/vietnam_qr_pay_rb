# frozen_string_literal: true

module VietnamQrPay
  # Provider-level metadata describing the QR scheme and nested provider data.
  Provider = Struct.new(
    :field_id,
    :name,
    :guid,
    :service,
    :data,
    keyword_init: true
  )
end
