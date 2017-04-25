module SortQuotationsTest
  extend ActiveSupport::Testing::Declarative

  test "returns lower prices first" do
    shop = create_shop(
      forward_to_correios: true,
      correios_code: "correioscode",
      correios_password: "correiosp@ss"
    )

    correios = mock_correios
    Correios.stub(:new, correios) do
      quotations = Quotations.
        new(shop, { shipping_zip: "90540140", products: [{ quantity: 1 }] }, Rails.logger).
        to_a

      assert_equal 2, quotations.size
      assert_equal 9, quotations[0].price
      assert_equal 10, quotations[1].price
    end

    assert correios.verify
  end

  test "returns in default order" do
    shop = create_shop(
      forward_to_correios: true,
      correios_code: "correioscode",
      correios_password: "correiosp@ss",
      order_by_price: false
    )

    correios = mock_correios
    Correios.stub(:new, correios) do
      quotations = Quotations.
        new(shop, { shipping_zip: "90540140", products: [{ quantity: 1 }] }, Rails.logger).
        to_a

      assert_equal 2, quotations.size
      assert_equal 10, quotations[0].price
      assert_equal 9, quotations[1].price
    end

    assert correios.verify
  end

  def mock_correios
    quotation_1 = MiniTest::Mock.new
    quotation_1.expect(:delivery_type_slug, "normal")
    quotation_1.expect(:price, 10)
    quotation_1.expect(:price, 10)
    quotation_1.expect(:as_json, {}, [{}])
    quotation_1.expect(:price, 10)
    quotation_1.expect(:shipping_method_id, nil)

    quotation_2 = MiniTest::Mock.new
    quotation_2.expect(:delivery_type_slug, "expressa")
    quotation_2.expect(:price, 9)
    quotation_2.expect(:price, 9)
    quotation_2.expect(:as_json, {}, [{}])
    quotation_2.expect(:price, 9)
    quotation_2.expect(:shipping_method_id, nil)

    instance = MiniTest::Mock.new
    instance.expect(:quote, [quotation_1, quotation_2], [{ products: [{ quantity: 1 }], shipping_zip: "90540140" }])
    instance
  end
end
