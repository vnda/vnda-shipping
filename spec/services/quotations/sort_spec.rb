require "rails_helper"

RSpec.describe Quotations, "sort" do
  it "returns lower prices first" do
    shop = create_shop(
      forward_to_correios: true,
      correios_code: "correioscode",
      correios_password: "correiosp@ss"
    )

    correios = mock_correios
    expect(Correios).to receive(:new).and_return(correios)
    quotations = Quotations.
      new(shop, { shipping_zip: "90540140", products: [{ quantity: 1 }] }, Rails.logger).
      to_a

    assert_equal 2, quotations.size
    assert_equal 9, quotations[0].price
    assert_equal 10, quotations[1].price
  end

  it "returns in default order" do
    shop = create_shop(
      forward_to_correios: true,
      correios_code: "correioscode",
      correios_password: "correiosp@ss",
      order_by_price: false
    )

    correios = mock_correios
    expect(Correios).to receive(:new).and_return(correios)
    quotations = Quotations.
      new(shop, { shipping_zip: "90540140", products: [{ quantity: 1 }] }, Rails.logger).
      to_a

    assert_equal 2, quotations.size
    assert_equal 10, quotations[0].price
    assert_equal 9, quotations[1].price
  end

  def create_shop(attributes = {})
    Shop.create!(attributes.merge(name: 'Loja', token: "a1b2c3", zip: "03320000"))
  end

  def mock_correios
    quotation_1 = double("quotation_1", delivery_type_slug: "normal", price: 10, deadline: 11,
      shipping_method_id: nil)

    quotation_2 = double("quotation_2", delivery_type_slug: "expressa", price: 9, deadline: 8,
      shipping_method_id: nil)

    correios = double("correios")
    expect(correios).to receive(:quote).
      with(products: [{ quantity: 1 }], shipping_zip: "90540140").
      and_return([quotation_1, quotation_2])
    correios
  end
end
