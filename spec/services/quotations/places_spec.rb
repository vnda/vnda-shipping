require "rails_helper"

RSpec.describe Quotations, "places" do
  it "quotations using places" do
    shop = create_shop(zip: "03320000")
    shipping_method = create_shipping_method(shop)

    quotations = new_places_quotations(shop)
    assert_equal 1, quotations.size

    assert_instance_of Quotation, quotations[0]
    assert_equal shop.id, quotations[0].shop_id
    assert_equal 1, quotations[0].cart_id
    assert_equal shipping_method.id, quotations[0].shipping_method_id
    expect(quotations[0].package).to eq(nil)
    assert_equal "Retirar na loja", quotations[0].name
    assert_equal 0, quotations[0].price
    assert_equal 8, quotations[0].deadline
    assert_equal "retirar-na-loja", quotations[0].slug
    assert_equal "Normal", quotations[0].delivery_type
    assert_nil quotations[0].deliver_company
    assert_nil quotations[0].quotation_id
    assert_equal "normal", quotations[0].delivery_type_slug
    assert_nil quotations[0].notice
  end

  it "increments returned deadline for places quotations" do
    shop = create_shop(zip: "03320000")
    create_shipping_method(shop)

    quotations = new_places_quotations(shop, products: [new_product(handling_days: 10)])
    expect(quotations.size).to eq(1)

    expect(quotations[0].deadline).to eq(18)
  end

  def create_shop(attributes = {})
    Shop.create!(attributes.merge(name: 'Loja', token: "a1b2c3", zip: "03320000"))
  end

  def new_product(params = {})
    params.reverse_merge(width: 7.0, height: 2.0, length: 14.0, quantity: 1, sku: "A1")
  end

  def new_places_quotations(shop, params = {})
    params = params.reverse_merge(
      cart_id: 1,
      shipping_zip: "80035120",
      products: [{ width: 7.0, height: 2.0, length: 14.0, quantity: 1, sku: "A1" }]
    )

    Quotations.new(shop, params, Rails.logger).to_a
  end

  def create_shipping_method(shop)
    shipping_method = shop.methods.create!(
      name: "Retirar na loja",
      description: "Retirar na loja",
      express: false,
      enabled: true,
      min_weigth: 0,
      max_weigth: 100,
      delivery_type_id: shop.delivery_types.first.id,
      data_origin: "places"
    )

    shipping_method.places.create!(name: "Loja", range: (80000000...81000000), deadline: 8)
    shipping_method
  end
end
