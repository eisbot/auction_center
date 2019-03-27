require 'test_helper'

class InvoiceTest < ActiveSupport::TestCase
  def setup
    super

    @result = results(:expired_participant)
    @not_sold_result = results(:without_offers_nobody)
    @user = users(:participant)
    @orphan_billing_profile = billing_profiles(:orphaned)
    @company_billing_profile = billing_profiles(:company)
    @payable_invoice = invoices(:payable)
    @orphaned_invoice = invoices(:orphaned)
  end

  def test_price_is_a_money_object
    invoice = Invoice.new(cents: 1000)

    assert_equal(Money.new(1000, Setting.auction_currency), invoice.price)

    invoice.cents = nil
    assert_equal(Money.new(0, Setting.auction_currency), invoice.price)
  end

  def test_required_fields
    invoice = Invoice.new
    refute(invoice.valid?)

    assert_equal(['must exist'], invoice.errors[:result], invoice.errors.full_messages)
    assert_equal(['must exist'], invoice.errors[:billing_profile], invoice.errors.full_messages)
    assert_equal(["can't be blank"], invoice.errors[:user_id], invoice.errors.full_messages)
    assert_equal(["can't be blank"], invoice.errors[:issue_date], invoice.errors.full_messages)
    assert_equal(["can't be blank"], invoice.errors[:due_date], invoice.errors.full_messages)

    invoice.result = @result
    invoice.billing_profile = @company_billing_profile
    invoice.user = @user
    invoice.issue_date = Time.zone.today
    invoice.due_date = Time.zone.today + Setting.payment_term
    invoice.cents = 1000

    assert(invoice.valid?)
  end

  def test_cents_must_be_an_integer
    invoice = prefill_invoice
    invoice.cents = 10.00

    refute(invoice.valid?)

    assert_equal(["must be an integer"], invoice.errors[:cents])
  end

  def test_filename
    assert_match(/invoice-no-\d+/, @payable_invoice.filename)

    invoice = prefill_invoice
    refute(invoice.filename)
  end

  def test_cents_must_be_positive
    invoice = prefill_invoice
    invoice.cents = -1000

    refute(invoice.valid?)

    assert_equal(["must be greater than 0"], invoice.errors[:cents])
  end

  def test_user_must_be_the_same_as_the_one_on_billing_or_nil
    invoice = Invoice.new
    invoice.result = @result
    invoice.billing_profile = @orphan_billing_profile
    invoice.user = @user

    refute(invoice.valid?)
    assert_equal(['must belong to the same user as invoice'], invoice.errors[:billing_profile])
  end

  def test_user_id_must_be_present_on_creation
    invoice = prefill_invoice
    invoice.user = nil
    refute(invoice.valid?(:create))

    invoice.user = @user
    assert(invoice.valid?(:create))

    invoice.save
    invoice.user = nil

    assert(invoice.valid?)
  end

  def test_default_status_is_issued
    invoice = prefill_invoice

    assert_equal('issued', invoice.status)
  end

  def test_paid_at_must_be_present_when_status_is_paid
    @payable_invoice.status = :paid

    refute(@payable_invoice.valid?)
    assert_equal(["can't be blank"], @payable_invoice.errors[:paid_at])
  end

  def test_create_from_result_only_works_when_result_exists_and_is_sold
    assert_raises(Errors::ResultNotFound) do
      Invoice.create_from_result("foo")
    end

    assert_raises(Errors::ResultNotSold) do
      Invoice.create_from_result(@not_sold_result.id)
    end
  end

  def test_a_persisted_invoice_has_items
    assert_equal(1, @payable_invoice.items.count)
  end

  def test_mark_as_paid_at
    time = Time.parse('2010-07-06 10:30 +0000')
    @payable_invoice.mark_as_paid_at(time)

    assert(@payable_invoice.paid?)
    assert(@payable_invoice.result.payment_received?)
    assert_equal(time.to_date + 14, @payable_invoice.result.registration_due_date)
    assert_equal(time, @payable_invoice.paid_at)
  end

  def test_invoice_items
    item = InvoiceItem.new(cents: 1200, name: :test_item)
    @payable_invoice.items =[item]

    assert_equal([item], @payable_invoice.items)
  end

  def test_invoice_title
    expected_number = @payable_invoice.number
    assert_equal("Invoice no. #{expected_number}", @payable_invoice.title)

    new_invoice = Invoice.new
    refute(new_invoice.title)
  end

  def prefill_invoice
    invoice = Invoice.new
    invoice.result = @result
    invoice.billing_profile = @company_billing_profile
    invoice.user = @user
    invoice.issue_date = Time.zone.today
    invoice.due_date = Time.zone.today + Setting.payment_term
    invoice.cents = 1000

    invoice
  end
end
