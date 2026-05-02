# frozen_string_literal: true

module VietnamQrPay
  # Provider names surfaced by decoded payloads and convenience builders.
  module QRProvider
    VIETQR = "VIETQR"
    VNPAY = "VNPAY"
  end

  # Globally unique identifiers used inside provider templates.
  module QRProviderGUID
    VNPAY = "A000000775"
    VIETQR = "A000000727"
  end

  # Top-level EMVCo field IDs used by the formats supported in this gem.
  module FieldID
    VERSION = "00"
    INIT_METHOD = "01"
    VNPAYQR = "26"
    VIETQR = "38"
    CATEGORY = "52"
    CURRENCY = "53"
    AMOUNT = "54"
    TIP_AND_FEE_TYPE = "55"
    TIP_AND_FEE_AMOUNT = "56"
    TIP_AND_FEE_PERCENT = "57"
    NATION = "58"
    MERCHANT_NAME = "59"
    CITY = "60"
    ZIP_CODE = "61"
    ADDITIONAL_DATA = "62"
    CRC = "63"
  end

  # Nested field IDs inside the provider template.
  module ProviderFieldID
    GUID = "00"
    DATA = "01"
    SERVICE = "02"
  end

  # VietQR currently distinguishes account-number and card-number transfer rails.
  module VietQRService
    BY_ACCOUNT_NUMBER = "QRIBFTTA"
    BY_CARD_NUMBER = "QRIBFTTC"
  end

  # Nested field IDs inside the VietQR consumer data block.
  module VietQRConsumerFieldID
    BANK_BIN = "00"
    BANK_NUMBER = "01"
  end

  # Additional data field IDs shared by VietQR and VNPayQR payloads.
  module AdditionalDataID
    BILL_NUMBER = "01"
    MOBILE_NUMBER = "02"
    STORE_LABEL = "03"
    LOYALTY_NUMBER = "04"
    REFERENCE_LABEL = "05"
    CUSTOMER_LABEL = "06"
    TERMINAL_LABEL = "07"
    PURPOSE_OF_TRANSACTION = "08"
    ADDITIONAL_CONSUMER_DATA_REQUEST = "09"
  end

  # EMVCo reserves IDs 65-79 for template extensions used by some providers.
  EVMCO_FIELD_IDS = (65..79).map { |value| format("%02d", value) }.freeze
  # Unreserved IDs 80-99 are used by provider-specific extensions such as MoMo.
  UNRESERVED_FIELD_IDS = (80..99).map { |value| format("%02d", value) }.freeze
end
