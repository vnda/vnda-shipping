module LocalQuotationsTest
  extend ActiveSupport::Testing::Declarative

  test "quotations using local" do
    shop = create_shop

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

    params = {
      cart_id: 1,
      package: "A1B2C3-1",
      shipping_zip: "80035120",
      products: [{ width: 7.0, height: 2.0, length: 14.0, quantity: 1, sku: "A1" }]
    }

    quotations = Quotations.new(shop, params, Rails.logger).to_a
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
end
