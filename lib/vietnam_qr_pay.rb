# frozen_string_literal: true

require_relative "vietnam_qr_pay/version"
require_relative "vietnam_qr_pay/models/additional_data"
require_relative "vietnam_qr_pay/models/bank"
require_relative "vietnam_qr_pay/models/bank_app"
require_relative "vietnam_qr_pay/models/consumer"
require_relative "vietnam_qr_pay/models/merchant"
require_relative "vietnam_qr_pay/models/provider"
require_relative "vietnam_qr_pay/constants"
require_relative "vietnam_qr_pay/crc16"
require_relative "vietnam_qr_pay/catalog"
require_relative "vietnam_qr_pay/qr_pay"

module VietnamQrPay
  # Base error type for gem-specific failures.
  class Error < StandardError; end

  class << self
    # Fetch a bank definition from the generated catalog by symbol or string key.
    #
    # Example:
    #   VietnamQrPay.bank(:vietinbank)
    #   VietnamQrPay.bank("vietinbank")
    def bank(key)
      BANKS_OBJECT.fetch(normalize_bank_key(key))
    end

    # Fetch bank app metadata from the generated catalog by symbol or string key.
    def bank_app(key)
      lookup_key = normalize_bank_value(key)
      BANK_APPS.find { |app| app.bank == lookup_key }
    end

    private

    # Catalog hashes are keyed by the upstream string identifiers converted to symbols.
    def normalize_bank_key(key)
      normalize_bank_value(key).to_sym
    end

    # The bundled source data uses lower-case string keys for banks.
    def normalize_bank_value(key)
      key.to_s.downcase
    end
  end
end
