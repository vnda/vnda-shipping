module PlacesQuotationsTest
  extend ActiveSupport::Testing::Declarative

  test "quotations using places" do
    shop = create_shop(zip: "03320000")

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

    params = {
      shipping_zip: "80035120",
      products: [{ width: 7.0, height: 2.0, length: 14.0, quantity: 1 }]
    }

    quotations = Quotations.new(shop, params, Rails.logger).to_a
    assert_equal 1, quotations.size

    assert_instance_of PlaceQuotation, quotations[0]
    assert_equal "Retirar na loja", quotations[0].name
    assert_equal 0, quotations[0].price
    assert_equal 8, quotations[0].deadline
    assert_equal "retirar-na-loja", quotations[0].slug
    assert_equal "Normal", quotations[0].delivery_type
    assert_equal "places", quotations[0].delivery_type_slug
    assert_equal "", quotations[0].notice
  end
end
