# frozen_string_literal: true

module VietnamQrPay
  # Additional payload metadata stored in field 62.
  AdditionalData = Struct.new(
    :bill_number,
    :mobile_number,
    :store,
    :loyalty_number,
    :reference,
    :customer_label,
    :terminal,
    :purpose,
    :data_request,
    keyword_init: true
  )
end
