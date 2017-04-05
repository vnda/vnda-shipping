module IntelipostQuotationsTest
  extend ActiveSupport::Testing::Declarative

  test "returns quotations using intelipost" do
    stub_intelipost_requests

    shop = create_shop(
      forward_to_intelipost: true,
      intelipost_token: "intel1tok3n",
      zip: "03320000"
    )

    params = {
      cart_id: 1,
      package: "A1B2C3-1",
      shipping_zip: "80035120",
      products: [{ width: 7.0, height: 2.0, length: 14.0, quantity: 1, sku: "A1" }]
    }

    quotations = Quotations.new(shop, params, Rails.logger).to_a
    assert_equal 2, quotations.size

    assert_instance_of Quotation, quotations[0]
    assert_equal "Entrega Normal", quotations[0].name
    assert_equal BigDecimal.new("8.72"), quotations[0].price
    assert_equal 5, quotations[0].deadline
    assert_equal "correios-pac", quotations[0].slug
    assert_equal "Normal", quotations[0].delivery_type
    assert_equal "Correios", quotations[0].deliver_company
    assert_equal "1181269286", quotations[0].quotation_id
    assert_equal "normal", quotations[0].delivery_type_slug
    assert_nil quotations[0].notice

    assert_instance_of Quotation, quotations[1]
    assert_equal "Entrega Expressa", quotations[1].name
    assert_equal 10.58, quotations[1].price
    assert_equal 1, quotations[1].deadline
    assert_equal "correios-esedex", quotations[1].slug
    assert_equal "Expressa", quotations[1].delivery_type
    assert_equal "Correios", quotations[1].deliver_company
    assert_equal "1181269286", quotations[1].quotation_id
    assert_equal "expressa", quotations[1].delivery_type_slug
    assert_nil quotations[1].notice
  end

  def stub_intelipost_requests
    stub_request(:post, "https://api.intelipost.com.br/api/v1/quote_by_product").
      with(:body => "{\"origin_zip_code\":\"03320-000\",\"destination_zip_code\":\"80035-120\",\"additional_information\":{\"sales_channel\":\"Loja\"},\"products\":[{\"sku\":\"A1\",\"cost_of_goods\":null,\"height\":2.0,\"length\":14.0,\"width\":7.0,\"weight\":null,\"description\":\"\",\"quantity\":1}]}",
        :headers => {'Accept'=>'application/json', 'Api-Key'=>'intel1tok3n', 'Content-Type'=>'application/json'}).
      to_return(:status => 200,
        :body => "{\"status\":\"OK\",\"messages\":[],\"content\":{\"origin_zip_code\":\"90540140\",\"destination_zip_code\":\"92025840\",\"platform\":\"quote_by_product\",\"additional_information\":{\"extra_cost_absolute\":null,\"lead_time_business_days\":null,\"free_shipping\":null,\"delivery_method_ids\":[],\"extra_cost_percentage\":null,\"tax_id\":null,\"client_type\":null,\"sales_channel\":\"www.desmobilia.com.br\",\"payment_type\":null,\"is_state_tax_payer\":null,\"shipped_date\":null},\"identification\":null,\"quoting_mode\":\"DYNAMIC_BOX_ALL_ITEMS\",\"id\":1181269286,\"client_id\":3868,\"created\":1486401529761,\"created_iso\":\"2017-02-06T15:18:49.761-02:00\",\"delivery_options\":[{\"delivery_method_id\":1,\"delivery_estimate_business_days\":5,\"provider_shipping_cost\":8.72,\"final_shipping_cost\":8.72,\"description\":\"Entrega Normal\",\"delivery_note\":null,\"removed_by_return_modes\":false,\"removed_by_quote_rules\":false,\"cubic_weight\":0.033,\"delivery_method_type\":\"STANDARD\",\"delivery_method_name\":\"Correios PAC\",\"logistic_provider_name\":\"Correios\",\"scheduling_enabled\":false,\"shown_to_client\":true},{\"delivery_method_id\":3,\"delivery_estimate_business_days\":1,\"provider_shipping_cost\":10.58,\"final_shipping_cost\":10.58,\"description\":\"Entrega Expressa\",\"delivery_note\":null,\"removed_by_return_modes\":false,\"removed_by_quote_rules\":false,\"cubic_weight\":0.033,\"delivery_method_type\":\"EXPRESS\",\"delivery_method_name\":\"Correios eSedex\",\"logistic_provider_name\":\"Correios\",\"scheduling_enabled\":false,\"shown_to_client\":true}],\"volumes\":[{\"weight\":0.3,\"cost_of_goods\":10.0,\"width\":7.0,\"height\":2.0,\"length\":14.0,\"description\":\"all items in one box\",\"sku_groups_ids\":[],\"product_category\":\"\",\"volume_type\":\"BOX\"}],\"cached\":false},\"time\":\"8.8 ms\",\"timezone\":\"America/Sao_Paulo\",\"locale\":\"pt_BR\"}",
        :headers => { "Content-Type" => "application/json" })
  end
end
