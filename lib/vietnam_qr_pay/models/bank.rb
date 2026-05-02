# frozen_string_literal: true

module VietnamQrPay
  # A generated bank catalog entry mirrored from the upstream JavaScript data.
  Bank = Struct.new(
    :key,
    :code,
    :name,
    :short_name,
    :bin,
    :viet_qr_status,
    :lookup_supported,
    :swift_code,
    :keywords,
    :deprecated,
    keyword_init: true
  ) do
    # Convenience export for callers that prefer hashes over structs.
    def to_h
      members.each_with_object({}) { |member, hash| hash[member] = public_send(member) }
    end
  end
end
