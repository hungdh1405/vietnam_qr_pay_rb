# frozen_string_literal: true

require "test_helper"

class QRPayTest < Minitest::Test
  def test_vietqr_decoding
    qr_content = "00020101021238530010A0000007270123000697041601092576788590208QRIBFTTA5303704540410005802VN62150811Chuyen tien6304BBB8"

    qr_pay = VietnamQrPay::QRPay.new(qr_content)

    assert_predicate qr_pay, :valid?
    assert_equal "01", qr_pay.version
    assert_equal VietnamQrPay::QRProvider::VIETQR, qr_pay.provider.name
    assert_equal VietnamQrPay::QRProviderGUID::VIETQR, qr_pay.provider.guid
    assert_equal "970416", qr_pay.consumer.bank_bin
    assert_equal "257678859", qr_pay.consumer.bank_number
    assert_equal "1000", qr_pay.amount
    assert_equal qr_content, qr_pay.build
  end

  def test_crc_with_three_byte_value
    qr_content = "00020101021138580010A000000727012800069704070114190304136010180208QRIBFTTA53037045802VN63040283"

    qr_pay = VietnamQrPay::QRPay.new(qr_content)

    assert_predicate qr_pay, :valid?
    assert_equal "970407", qr_pay.consumer.bank_bin
    assert_equal "19030413601018", qr_pay.consumer.bank_number
    assert_equal qr_content, qr_pay.build
  end

  def test_invalid_crc_for_vietqr
    qr_pay = VietnamQrPay::QRPay.new("00020101021238530010A0000007270123000697041601092576788590208QRIBFTTA5303704540410005802VN62150811Chuyen tien6304BBB5")

    refute_predicate qr_pay, :valid?
  end

  def test_lowercase_crc_is_accepted
    qr_content = "00020101021138540010A00000072701240006970422011003523509170208QRIBFTTA53037045802VN630479db"

    qr_pay = VietnamQrPay::QRPay.new(qr_content)

    assert_predicate qr_pay, :valid?
    assert_equal "79DB", qr_pay.build[-4, 4]
  end

  def test_vnpay_qr_decoding
    qr_content = "00020101021126280010A000000775011001087990425204597753037045802VN5909MYPHAMHER6005HANOI62260311MY PHAM HER0707MPHER0163041C50"

    qr_pay = VietnamQrPay::QRPay.new(qr_content)

    assert_predicate qr_pay, :valid?
    assert_equal VietnamQrPay::QRProvider::VNPAY, qr_pay.provider.name
    assert_equal VietnamQrPay::QRProviderGUID::VNPAY, qr_pay.provider.guid
    assert_equal "MY PHAM HER", qr_pay.additional_data.store
    assert_equal "MPHER01", qr_pay.additional_data.terminal
    assert_equal "1C50", qr_pay.crc
    assert_equal qr_content, qr_pay.build
  end

  def test_second_vnpay_qr_decoding
    qr_content = "00020101021126280010A000000775011001A80187905204549953037045802VN5907SUNFLY16005HaNoi62290313SUNFLY ONLINE0708SUNFLY016304AE6F"

    qr_pay = VietnamQrPay::QRPay.new(qr_content)

    assert_predicate qr_pay, :valid?
    assert_equal "SUNFLY ONLINE", qr_pay.additional_data.store
    assert_equal "SUNFLY01", qr_pay.additional_data.terminal
    assert_equal qr_content, qr_pay.build
  end

  def test_personal_vnpay_qr_decoding
    qr_pay = VietnamQrPay::QRPay.new("00020101021002020103069084010411VNPayWallet071003933571580809Lê Anh Tú09051000010037041107content63042678")

    assert_predicate qr_pay, :valid?
    assert_nil qr_pay.provider.name
    assert_nil qr_pay.provider.guid
  end

  def test_invalid_crc_for_vnpay_qr
    qr_pay = VietnamQrPay::QRPay.new("00020101021126280010A000000775011001087990425204597753037045802VN5909MYPHAMHER6005HANOI62260311MY PHAM HER0707MPHER0163041C55")

    refute_predicate qr_pay, :valid?
  end

  def test_momo_generation
    account_number = "99MM24011M34875080"

    qr_pay = VietnamQrPay::QRPay.init_viet_qr(
      bank_bin: VietnamQrPay::BanksObject[:banviet].bin,
      bank_number: account_number
    )
    qr_pay.additional_data.reference = "MOMOW2W#{account_number[10..]}"
    qr_pay.set_unreserved_field("80", "046")

    expected = "00020101021138620010A00000072701320006970454011899MM24011M348750800208QRIBFTTA53037045802VN62190515MOMOW2W3487508080030466304EBC8"
    assert_equal expected, qr_pay.build
  end

  def test_zalopay_generation
    qr_pay = VietnamQrPay::QRPay.init_viet_qr(
      bank_bin: VietnamQrPay::BanksObject[:banviet].bin,
      bank_number: "99ZP24009M07248267"
    )

    expected = "00020101021138620010A00000072701320006970454011899ZP24009M072482670208QRIBFTTA53037045802VN6304073C"
    assert_equal expected, qr_pay.build
  end

  def test_airpay_decoding
    qr_pay = VietnamQrPay::QRPay.new("00020101021126610013vn.airpay.www014000000201010100064185noC4efDjGKq0or5GbeBz5204581253037045910RESTAURANT6009HOCHIMINH5802VN6304DA5C")

    assert_predicate qr_pay, :valid?
    assert_nil qr_pay.provider.name
    assert_equal "vn.airpay.www", qr_pay.provider.guid
  end

  def test_evn_qr_roundtrip
    qr_content = "000201010211262400020001140100101114-0195204490053037045802VN5931EVN CONG TY DIEN LUC THANH XUAN6006Ha Noi62450302000613PD000000000000702000812TT tien dien6304DC30"

    qr_pay = VietnamQrPay::QRPay.new(qr_content)

    assert_predicate qr_pay, :valid?
    assert_equal "26", qr_pay.provider.field_id
    assert_equal "00", qr_pay.provider.guid
    assert_equal "PD00000000000", qr_pay.additional_data.customer_label
    assert_equal qr_content, qr_pay.build
  end

  def test_static_vietqr_generation
    qr_pay = VietnamQrPay::QRPay.init_viet_qr(
      bank_bin: VietnamQrPay::BanksObject[:acb].bin,
      bank_number: "257678859"
    )

    assert_equal "11", qr_pay.init_method
    assert_equal "00020101021138530010A0000007270123000697041601092576788590208QRIBFTTA53037045802VN6304AE9F", qr_pay.build
  end

  def test_dynamic_vietqr_generation
    qr_pay = VietnamQrPay::QRPay.init_viet_qr(
      bank_bin: VietnamQrPay::BanksObject[:acb].bin,
      bank_number: "257678859",
      amount: "10000",
      purpose: "Chuyen tien"
    )

    assert_equal "12", qr_pay.init_method
    assert_equal "00020101021238530010A0000007270123000697041601092576788590208QRIBFTTA53037045405100005802VN62150811Chuyen tien630453E6", qr_pay.build
  end

  def test_vnpay_generation
    qr_pay = VietnamQrPay::QRPay.init_vnpay_qr(
      merchant_id: "0102154778",
      merchant_name: "TUGIACOMPANY",
      store: "TU GIA COMPUTER",
      terminal: "TUGIACO1"
    )

    assert_equal "00020101021126280010A0000007750110010215477853037045802VN5912TUGIACOMPANY62310315TU GIA COMPUTER0708TUGIACO16304DF44", qr_pay.build
  end

  def test_evmco_fields_are_built_and_decoded
    qr_pay = VietnamQrPay::QRPay.init_viet_qr(
      bank_bin: VietnamQrPay::BanksObject[:acb].bin,
      bank_number: "257678859"
    )
    qr_pay.set_evmco_field("65", "EXTRA")

    rebuilt = VietnamQrPay::QRPay.new(qr_pay.build)

    assert_predicate rebuilt, :valid?
    assert_equal "EXTRA", rebuilt.evmco["65"]
  end
end
