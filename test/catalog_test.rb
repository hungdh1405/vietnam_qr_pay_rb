# frozen_string_literal: true

require "test_helper"

class CatalogTest < Minitest::Test
  def test_bank_catalog_matches_reference_surface
    assert_equal 61, VietnamQrPay::Banks.size
    assert_equal 60, VietnamQrPay::BankApps.size
    assert_equal "970416", VietnamQrPay.bank(:acb).bin
    assert_equal "ACB", VietnamQrPay.bank(:acb).code
    assert_equal VietnamQrPay::BankKey::LPBANK, VietnamQrPay.bank(:lpbank).key
    assert_equal true, VietnamQrPay.bank(:oceanbank).deprecated
  end

  def test_bank_app_lookup
    bank_app = VietnamQrPay.bank_app("acb")

    refute_nil bank_app
    assert_equal "mobile.acb.com.vn", bank_app.package_id
    assert_equal false, bank_app.support_vnpay_qr
  end
end
