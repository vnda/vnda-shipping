module GoogleMapsQuotationsTest
  extend ActiveSupport::Testing::Declarative

  test "quotations using google maps" do
    shop = create_shop(zip: "03320000")

    quotations = new_googlemaps_quotations(shop)
    assert_equal 1, quotations.size

    assert_instance_of Quotation, quotations[0]
    assert_equal "CEP80035120", quotations[0].name
    assert_equal 10, quotations[0].price
    assert_equal 0, quotations[0].deadline
    assert_equal "cep80035120", quotations[0].slug
    assert_equal "Normal", quotations[0].delivery_type
    assert_nil quotations[0].deliver_company
    assert_nil quotations[0].quotation_id
    assert_equal "normal", quotations[0].delivery_type_slug
    assert_nil quotations[0].notice
  end

  test "increments returned deadline for googlemaps quotations" do
    shop = create_shop(zip: "03320000")

    quotations = new_googlemaps_quotations(shop, additional_deadline: 10)
    assert_equal 1, quotations.size

    assert_equal 10, quotations[0].deadline
  end

  def new_googlemaps_quotations(shop, params = {})
    stub_google_maps_requests

    shipping_method = shop.methods.create!(
      name: "CEP80035120",
      description: "CEP80035120",
      express: false,
      enabled: true,
      min_weigth: 0,
      max_weigth: 100,
      delivery_type_id: shop.delivery_types.first.id,
      data_origin: "google_maps",
      mid: "a1b2c3"
    )

    kml = Rails.root.join("test/fixtures/80035120.kml").read
    shipping_method.build_or_update_map_rules_from(Nokogiri::XML(kml))
    shipping_method.map_rules.first.update(price: 10)

    params = params.reverse_merge(
      cart_id: 1,
      package: "A1B2C3-1",
      shipping_zip: "80035120",
      products: [{ width: 7.0, height: 2.0, length: 14.0, quantity: 1, sku: "A1" }]
    )

    Quotations.new(shop, params, Rails.logger).to_a
  end

  def stub_google_maps_requests
    stub_request(:get, "https://maps.googleapis.com/maps/api/geocode/json?components=postal_code:80035120&key&region=br").
      to_return(status: 200,
        body: Rails.root.join("test/fixtures/80035120.json").read,
        headers: { "Content-Type" => "application/json" })
  end
end
