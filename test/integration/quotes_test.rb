require 'test_helper'

class QuotesTest < ActionDispatch::IntegrationTest
  test "correios return unauthorized if no token" do
    post "/quote", token: nil
    assert_equal 401, status
  end

  test "correios return 400 if no mandatory parameters" do
    shop = create_shop

    post "/quote", token: shop.token
    assert_equal 400, status
  end

  test "correios return 200 if quotation created" do
    stub_request(:get, "http://ws.correios.com.br/calculador/CalcPrecoPrazo.asmx?WSDL").
      to_return(status: 200,
        body: Rails.root.join("test/fixtures/calc_preco_prazo.wsdl").read,
        headers: { "Content-Type" => "text/xml; charset=utf-8" })

    stub_request(:post, "http://ws.correios.com.br/calculador/CalcPrecoPrazo.asmx").
      with(body: Rails.root.join("test/fixtures/calc_preco_prazo.request.xml").read.strip).
      to_return(status: 200,
        body: Rails.root.join("test/fixtures/calc_preco_prazo.response.xml").read,
        headers: { "Content-Type" => "text/xml; charset=utf-8" })

    shop = create_shop(
      forward_to_correios: true,
      correios_code: "correioscode",
      correios_password: "correiosp@ss"
    )

    post "/quote", token: shop.token, origin_zip: "03320000", shipping_zip: "80035120", products: [{ width: 7.0, height: 2.0, length: 14.0, quantity: 1 }]

    assert_equal 200, status

    quotations = JSON.load(body)

    assert_equal 2, quotations.size

    assert_equal "", quotations[0]["cotation_id"]
    assert_equal "Normal", quotations[0]["name"]
    assert_equal 18.3, quotations[0]["price"]
    assert_equal 7, quotations[0]["deadline"]
    assert_equal "41106", quotations[0]["slug"]
    assert_equal "Normal", quotations[0]["delivery_type"]
    assert_equal "normal", quotations[0]["delivery_type_slug"]
    assert_equal "Correios", quotations[0]["deliver_company"]
    assert_equal "", quotations[0]["notice"]

    assert_equal "", quotations[1]["cotation_id"]
    assert_equal "Expressa", quotations[1]["name"]
    assert_equal 26, quotations[1]["price"]
    assert_equal 1, quotations[1]["deadline"]
    assert_equal "40010", quotations[1]["slug"]
    assert_equal "Expressa", quotations[1]["delivery_type"]
    assert_equal "expressa", quotations[1]["delivery_type_slug"]
    assert_equal "Correios", quotations[1]["deliver_company"]
    assert_equal "", quotations[1]["notice"]
  end

  def create_shop(attributes = {})
    Shop.create!({ name: 'Loja', token: "a1b2c3" }.reverse_merge(attributes))
  end
end
