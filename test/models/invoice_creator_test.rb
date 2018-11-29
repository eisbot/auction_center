require 'test_helper'

class InvoiceCreatorTest < ActiveSupport::TestCase
  def setup
    super

    @result = results(:expired_participant)
    @result_without_offer = results(:without_offers_nobody)
  end

  def test_an_invoice_is_prefilled_with_data_from_winning_offer
    invoice_creator = InvoiceCreator.new(@result.id)
    invoice = invoice_creator.call

    assert(invoice.is_a?(Invoice))
    assert_equal(@result, invoice.result)
    assert_equal(@result.user, invoice.user)
  end

  def test_return_early_if_result_does_not_exist
    invoice_creator = InvoiceCreator.new(:foo)
    invoice = invoice_creator.call

    assert_nil(invoice)
  end

  def test_returns_early_if_result_does_not_have_a_winning_offer
    invoice_creator = InvoiceCreator.new(@result_without_offer)
    invoice = invoice_creator.call

    assert_nil(invoice)
  end
end
