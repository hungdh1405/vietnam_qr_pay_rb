# frozen_string_literal: true

module VietnamQrPay
  # Core object for parsing, inspecting, and building Vietnamese payment QR payloads.
  #
  # The object keeps a mutable in-memory representation of the EMVCo TLV
  # payload so callers can decode an existing string, change selected fields,
  # and rebuild a valid payload with a regenerated CRC.
  class QRPay
    attr_accessor :version,
                  :init_method,
                  :provider,
                  :merchant,
                  :consumer,
                  :category,
                  :currency,
                  :amount,
                  :tip_and_fee_type,
                  :tip_and_fee_amount,
                  :tip_and_fee_percent,
                  :nation,
                  :city,
                  :zip_code,
                  :additional_data,
                  :crc,
                  :evmco,
                  :unreserved

    def initialize(content = nil)
      @valid = true
      @provider = Provider.new
      @consumer = Consumer.new
      @merchant = Merchant.new
      @additional_data = AdditionalData.new
      @evmco = {}
      @unreserved = {}
      parse(content) if content && !content.empty?
    end

    def valid?
      @valid
    end

    alias is_valid valid?

    # Parses an existing payload.
    #
    # Parsing always resets the current object first so reusing a QRPay instance
    # cannot leak fields from a previous payload.
    def parse(content)
      reset_parsed_state

      return invalidate! if content.nil? || content.length < 4
      return invalidate! unless self.class.verify_crc(content)

      parse_root_content(content)
      self
    end

    # Builds a new payload from the current in-memory structure.
    def build
      provider_data_content =
        case provider.guid
        when QRProviderGUID::VIETQR
          # VietQR stores bank BIN and account/card number inside a nested
          # provider template rather than directly on the root payload.
          [
            self.class.field_data(VietQRConsumerFieldID::BANK_BIN, consumer.bank_bin),
            self.class.field_data(VietQRConsumerFieldID::BANK_NUMBER, consumer.bank_number)
          ].join
        when QRProviderGUID::VNPAY
          # VNPayQR stores the merchant identifier directly in provider data.
          merchant.id.to_s
        else
          # Unknown providers are preserved so decode -> build stays lossless.
          provider.data.to_s
        end

      provider_content = [
        self.class.field_data(ProviderFieldID::GUID, provider.guid),
        self.class.field_data(ProviderFieldID::DATA, provider_data_content),
        self.class.field_data(ProviderFieldID::SERVICE, provider.service)
      ].join

      additional_data_content = [
        self.class.field_data(AdditionalDataID::BILL_NUMBER, additional_data.bill_number),
        self.class.field_data(AdditionalDataID::MOBILE_NUMBER, additional_data.mobile_number),
        self.class.field_data(AdditionalDataID::STORE_LABEL, additional_data.store),
        self.class.field_data(AdditionalDataID::LOYALTY_NUMBER, additional_data.loyalty_number),
        self.class.field_data(AdditionalDataID::REFERENCE_LABEL, additional_data.reference),
        self.class.field_data(AdditionalDataID::CUSTOMER_LABEL, additional_data.customer_label),
        self.class.field_data(AdditionalDataID::TERMINAL_LABEL, additional_data.terminal),
        self.class.field_data(AdditionalDataID::PURPOSE_OF_TRANSACTION, additional_data.purpose),
        self.class.field_data(AdditionalDataID::ADDITIONAL_CONSUMER_DATA_REQUEST, additional_data.data_request)
      ].join

      # The CRC field contains the field ID and fixed length before the value
      # is calculated over the complete payload prefix.
      content = [
        self.class.field_data(FieldID::VERSION, version || "01"),
        self.class.field_data(FieldID::INIT_METHOD, init_method || "11"),
        self.class.field_data(provider.field_id, provider_content),
        self.class.field_data(FieldID::CATEGORY, category),
        self.class.field_data(FieldID::CURRENCY, currency || "704"),
        self.class.field_data(FieldID::AMOUNT, amount),
        self.class.field_data(FieldID::TIP_AND_FEE_TYPE, tip_and_fee_type),
        self.class.field_data(FieldID::TIP_AND_FEE_AMOUNT, tip_and_fee_amount),
        self.class.field_data(FieldID::TIP_AND_FEE_PERCENT, tip_and_fee_percent),
        self.class.field_data(FieldID::NATION, nation || "VN"),
        self.class.field_data(FieldID::MERCHANT_NAME, merchant.name),
        self.class.field_data(FieldID::CITY, city),
        self.class.field_data(FieldID::ZIP_CODE, zip_code),
        self.class.field_data(FieldID::ADDITIONAL_DATA, additional_data_content),
        build_fields(evmco),
        build_fields(unreserved),
        "#{FieldID::CRC}04"
      ].join

      content + self.class.gen_crc_code(content)
    end

    # Assigns an EMVCo extension field in the 65-79 range.
    def set_evmco_field(id, value)
      evmco[id.to_s] = value.to_s
    end

    # Assigns an unreserved extension field in the 80-99 range.
    def set_unreserved_field(id, value)
      unreserved[id.to_s] = value.to_s
    end

    class << self
      # Builds a VietQR-oriented object with sensible defaults for static or dynamic transfers.
      def init_viet_qr(bank_bin:, bank_number:, amount: nil, purpose: nil, service: VietQRService::BY_ACCOUNT_NUMBER)
        qr = new
        # VietQR uses init method 11 for static QR and 12 when amount is fixed.
        qr.init_method = amount ? "12" : "11"
        qr.provider.field_id = FieldID::VIETQR
        qr.provider.guid = QRProviderGUID::VIETQR
        qr.provider.name = QRProvider::VIETQR
        qr.provider.service = service
        qr.consumer.bank_bin = bank_bin
        qr.consumer.bank_number = bank_number
        qr.amount = amount
        qr.additional_data.purpose = purpose
        qr
      end

      # Builds a VNPayQR-oriented object with the merchant block prepopulated.
      def init_vnpay_qr(
        merchant_id:,
        merchant_name:,
        store:,
        terminal:,
        amount: nil,
        purpose: nil,
        bill_number: nil,
        mobile_number: nil,
        loyalty_number: nil,
        reference: nil,
        customer_label: nil
      )
        qr = new
        qr.merchant.id = merchant_id
        qr.merchant.name = merchant_name
        qr.provider.field_id = FieldID::VNPAYQR
        qr.provider.guid = QRProviderGUID::VNPAY
        qr.provider.name = QRProvider::VNPAY
        qr.amount = amount
        qr.additional_data.purpose = purpose
        qr.additional_data.bill_number = bill_number
        qr.additional_data.mobile_number = mobile_number
        qr.additional_data.store = store
        qr.additional_data.terminal = terminal
        qr.additional_data.loyalty_number = loyalty_number
        qr.additional_data.reference = reference
        qr.additional_data.customer_label = customer_label
        qr
      end

      # Verifies the trailing CRC against the payload prefix.
      def verify_crc(content)
        check_content = content[0...-4]
        crc_code = content[-4, 4].to_s.upcase
        crc_code == gen_crc_code(check_content)
      end

      # Returns the CRC value formatted as the upper-case 4-character suffix expected by EMVCo payloads.
      def gen_crc_code(content)
        format("%04X", CRC16.crc16ccitt(content))
      end

      # Serializes a single TLV field. Invalid or blank values are omitted.
      def field_data(id, value)
        field_id = id.to_s
        field_value = value.to_s
        return "" if field_id.length != 2 || field_value.empty?

        "#{field_id}#{format('%02d', field_value.length)}#{field_value}"
      end

      private

      # Slices a TLV field into its four logical parts for the parser loops below.
      def slice_content(content)
        id = content[0, 2]
        length = content[2, 2].to_i
        value = content[4, length].to_s
        next_value = content[(4 + length)..] || ""
        { id: id, length: length, value: value, next_value: next_value }
      end
    end

    private

    def parse_root_content(content)
      next_value = content

      while next_value.length > 4
        field = self.class.send(:slice_content, next_value)
        return invalidate! if field[:value].length != field[:length]

        id = field[:id]
        value = field[:value]

        case id
        when FieldID::VERSION
          self.version = value
        when FieldID::INIT_METHOD
          self.init_method = value
        when FieldID::VIETQR, FieldID::VNPAYQR
          provider.field_id = id
          parse_provider_info(value)
        when FieldID::CATEGORY
          self.category = value
        when FieldID::CURRENCY
          self.currency = value
        when FieldID::AMOUNT
          self.amount = value
        when FieldID::TIP_AND_FEE_TYPE
          self.tip_and_fee_type = value
        when FieldID::TIP_AND_FEE_AMOUNT
          self.tip_and_fee_amount = value
        when FieldID::TIP_AND_FEE_PERCENT
          self.tip_and_fee_percent = value
        when FieldID::NATION
          self.nation = value
        when FieldID::MERCHANT_NAME
          merchant.name = value
        when FieldID::CITY
          self.city = value
        when FieldID::ZIP_CODE
          self.zip_code = value
        when FieldID::ADDITIONAL_DATA
          parse_additional_data(value)
        when FieldID::CRC
          self.crc = value
        else
          # Preserve extension data rather than discarding it so callers can
          # round-trip provider-specific payload variants.
          if EVMCO_FIELD_IDS.include?(id)
            evmco[id] = value
          elsif UNRESERVED_FIELD_IDS.include?(id)
            unreserved[id] = value
          end
        end

        next_value = field[:next_value]
      end
    end

    def parse_provider_info(content)
      fields = {}
      next_value = content

      while next_value.length > 4
        field = self.class.send(:slice_content, next_value)
        return invalidate! if field[:value].length != field[:length]

        fields[field[:id]] = field[:value]
        next_value = field[:next_value]
      end

      provider.guid = fields[ProviderFieldID::GUID]
      provider.service = fields[ProviderFieldID::SERVICE]
      provider.data = fields[ProviderFieldID::DATA]

      case provider.guid
      when QRProviderGUID::VNPAY
        provider.name = QRProvider::VNPAY
        merchant.id = provider.data
      when QRProviderGUID::VIETQR
        provider.name = QRProvider::VIETQR
        parse_vietqr_consumer(provider.data.to_s)
      end
    end

    def parse_vietqr_consumer(content)
      next_value = content

      while next_value.length > 4
        field = self.class.send(:slice_content, next_value)
        return invalidate! if field[:value].length != field[:length]

        case field[:id]
        when VietQRConsumerFieldID::BANK_BIN
          consumer.bank_bin = field[:value]
        when VietQRConsumerFieldID::BANK_NUMBER
          consumer.bank_number = field[:value]
        end

        next_value = field[:next_value]
      end
    end

    def parse_additional_data(content)
      next_value = content

      while next_value.length > 4
        field = self.class.send(:slice_content, next_value)
        return invalidate! if field[:value].length != field[:length]

        case field[:id]
        when AdditionalDataID::BILL_NUMBER
          additional_data.bill_number = field[:value]
        when AdditionalDataID::MOBILE_NUMBER
          additional_data.mobile_number = field[:value]
        when AdditionalDataID::STORE_LABEL
          additional_data.store = field[:value]
        when AdditionalDataID::LOYALTY_NUMBER
          additional_data.loyalty_number = field[:value]
        when AdditionalDataID::REFERENCE_LABEL
          additional_data.reference = field[:value]
        when AdditionalDataID::CUSTOMER_LABEL
          additional_data.customer_label = field[:value]
        when AdditionalDataID::TERMINAL_LABEL
          additional_data.terminal = field[:value]
        when AdditionalDataID::PURPOSE_OF_TRANSACTION
          additional_data.purpose = field[:value]
        when AdditionalDataID::ADDITIONAL_CONSUMER_DATA_REQUEST
          additional_data.data_request = field[:value]
        end

        next_value = field[:next_value]
      end
    end

    # Extension fields must be emitted in ascending field order for stable output.
    def build_fields(fields)
      fields.keys.sort.map { |key| self.class.field_data(key, fields[key]) }.join
    end

    def invalidate!
      @valid = false
      self
    end

    # Recreates the mutable field containers so the object goes back to a clean state.
    def reset_parsed_state
      @valid = true
      @provider = Provider.new
      @consumer = Consumer.new
      @merchant = Merchant.new
      @additional_data = AdditionalData.new
      @evmco = {}
      @unreserved = {}
      self.version = nil
      self.init_method = nil
      self.category = nil
      self.currency = nil
      self.amount = nil
      self.tip_and_fee_type = nil
      self.tip_and_fee_amount = nil
      self.tip_and_fee_percent = nil
      self.nation = nil
      self.city = nil
      self.zip_code = nil
      self.crc = nil
    end
  end
end
