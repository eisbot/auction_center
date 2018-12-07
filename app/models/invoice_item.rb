class InvoiceItem < ApplicationRecord
  belongs_to :invoice, required: true
  validates :cents, numericality: { only_integer: true, greater_than: 0 }

  def price
    Money.new(cents, Setting.auction_currency)
  end
end
