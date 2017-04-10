module CorreiosQuotationsTest
  extend ActiveSupport::Testing::Declarative

  test "returns quotations using correios" do
    shop = create_shop(
      forward_to_correios: true,
      correios_code: "correioscode",
      correios_password: "correiosp@ss",
      zip: "03320000"
    )

    quotations = new_correios_quotations(shop)
    assert_equal 2, quotations.size

    assert_instance_of Quotation, quotations[0]
    assert_equal shop.id, quotations[0].shop_id
    assert_equal 1, quotations[0].cart_id
    assert_equal shop.methods.where(name: "Normal").first.id, quotations[0].shipping_method_id
    assert_equal "A1B2C3-01", quotations[0].package
    assert_equal "Normal", quotations[0].name
    assert_equal 18.3, quotations[0].price
    assert_equal 7, quotations[0].deadline
    assert_equal "41106", quotations[0].slug
    assert_equal "Normal", quotations[0].delivery_type
    assert_equal "Correios", quotations[0].deliver_company
    assert_nil quotations[0].quotation_id
    assert_equal "normal", quotations[0].delivery_type_slug
    assert_nil quotations[0].notice

    assert_instance_of Quotation, quotations[1]
    assert_equal shop.id, quotations[1].shop_id
    assert_equal 1, quotations[1].cart_id
    assert_equal shop.methods.where(name: "Expressa").first.id, quotations[1].shipping_method_id
    assert_equal "A1B2C3-01", quotations[1].package
    assert_equal "Expressa", quotations[1].name
    assert_equal 26, quotations[1].price
    assert_equal 1, quotations[1].deadline
    assert_equal "40010", quotations[1].slug
    assert_equal "Expressa", quotations[1].delivery_type
    assert_equal "Correios", quotations[1].deliver_company
    assert_nil quotations[1].quotation_id
    assert_equal "expressa", quotations[1].delivery_type_slug
    assert_nil quotations[1].notice
  end

  test "increments returned deadline for correios quotations" do
    shop = create_shop(
      forward_to_correios: true,
      correios_code: "correioscode",
      correios_password: "correiosp@ss",
      zip: "03320000"
    )

    quotations = new_correios_quotations(shop, additional_deadline: 10)
    assert_equal 2, quotations.size

    assert_equal 17, quotations[0].deadline
    assert_equal 11, quotations[1].deadline
  end

  def new_correios_quotations(shop, params = {})
    stub_correios_requests

    params = params.reverse_merge(
      cart_id: 1,
      package: "A1B2C3-01",
      shipping_zip: "80035120",
      products: [{ width: 7.0, height: 2.0, length: 14.0, quantity: 1, sku: "A1" }]
    )

    Quotations.new(shop, params, Rails.logger).to_a
  end

  def stub_correios_requests
    stub_request(:get, "http://ws.correios.com.br/calculador/CalcPrecoPrazo.asmx?WSDL").
      to_return(status: 200,
        body: Rails.root.join("test/fixtures/calc_preco_prazo.wsdl").read,
        headers: { "Content-Type" => "text/xml; charset=utf-8" })

    stub_request(:post, "http://ws.correios.com.br/calculador/CalcPrecoPrazo.asmx").
      with(body: Rails.root.join("test/fixtures/calc_preco_prazo.request.xml").read.strip).
      to_return(status: 200,
        body: Rails.root.join("test/fixtures/calc_preco_prazo.response.xml").read,
        headers: { "Content-Type" => "text/xml; charset=utf-8" })
  end
end
