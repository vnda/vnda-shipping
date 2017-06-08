require "rails_helper"

RSpec.describe Quotations, "local" do
  it "quotations using local" do
    shop = create_shop

    quotations = new_local_quotations(shop)
    assert_equal 1, quotations.size

    assert_instance_of Quotation, quotations[0]
    assert_equal "Retirar na loja", quotations[0].name
    assert_equal 12, quotations[0].price
    assert_equal 1, quotations[0].deadline
    assert_equal "retirar-na-loja", quotations[0].slug
    assert_equal "Normal", quotations[0].delivery_type
    assert_equal "normal", quotations[0].delivery_type_slug
    assert_nil quotations[0].notice
  end

  it "increments returned deadline for local quotations" do
    shop = create_shop

    quotations = new_local_quotations(shop, products: [new_product(handling_days: 10)])
    expect(quotations.size).to eq(1)

    expect(quotations[0].deadline).to eq(11)
  end

  it "filter shiping methods by package" do
    shop = create_shop

    shop.methods.create!(
      name: "Transportadora 1",
      description: "Transportadora 1",
      express: false,
      enabled: true,
      min_weigth: 0,
      max_weigth: 1000,
      delivery_type_id: shop.delivery_types.first.id,
      data_origin: "local",
      package_pattern: "^abc"
    ).zip_rules.create!(range: (80000000...81000000), price: 4, deadline: 1)

    shop.methods.create!(
      name: "Transportadora 2",
      description: "Transportadora 2",
      express: false,
      enabled: true,
      min_weigth: 0,
      max_weigth: 1000,
      delivery_type_id: shop.delivery_types.first.id,
      data_origin: "local",
      package_pattern: "^A1"
    ).zip_rules.create!(range: (80000000...81000000), price: 5, deadline: 1)

    quotations = new_local_quotations(shop, products: [new_product(handling_days: 10)])
    expect(quotations.size).to eq(1)
    expect(quotations[0].price).to eq(5)
  end

  def create_shop(attributes = {})
    Shop.create!(attributes.merge(name: 'Loja', token: "a1b2c3", zip: "03320000"))
  end

  def new_product(params = {})
    params.reverse_merge(width: 7.0, height: 2.0, length: 14.0, quantity: 1, sku: "A1")
  end

  def new_local_quotations(shop, params = {})
    shipping_method = shop.methods.create!(
      name: "Retirar na loja",
      description: "Retirar na loja",
      express: false,
      enabled: true,
      min_weigth: 0,
      max_weigth: 1000,
      delivery_type_id: shop.delivery_types.first.id,
      data_origin: "local"
    )

    shipping_method.zip_rules.create!(range: (80000000...81000000), price: 12, deadline: 1)

    params = params.reverse_merge(
      cart_id: 1,
      package: "A1B2C3-1",
      shipping_zip: "80035120",
      products: [{ width: 7.0, height: 2.0, length: 14.0, quantity: 1, sku: "A1" }]
    )

    Quotations.new(shop, params, Rails.logger).to_a
  end
end
