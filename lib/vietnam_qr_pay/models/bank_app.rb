# frozen_string_literal: true

module VietnamQrPay
  # App-deeplink metadata for a bank mobile app.
  BankApp = Struct.new(
    :bank,
    :scheme,
    :package_id,
    :app_store_id,
    :support_viet_qr,
    :support_vnpay_qr,
    keyword_init: true
  ) do
    # Convenience export for callers that prefer hashes over structs.
    def to_h
      members.each_with_object({}) { |member, hash| hash[member] = public_send(member) }
    end
  end
end
