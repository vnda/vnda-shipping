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

  test "generates a new error message when no quotations" do
    shop = create_shop

    quotations = MiniTest::Mock.new
    quotations.expect(:to_a, [])

    Quotations.stub(:new, quotations) do
      post "/quote?token=#{shop.token}", shipping_zip: "12946636", products: [{ quantity: 1 }]

      response.status.must_equal(400)
      response.body.must_equal({ error: "Não existem opções de entrega para este endereço." }.to_json)

      shop.reload.shipping_errors.size.must_equal(1)
      shop.reload.shipping_errors[0].message.must_equal("Não existem opções de entrega para este endereço.")
    end
  end

  test "returns a friendly error message when no quotations" do
    shop = create_shop
    shop.shipping_friendly_errors.create!(rule: "Não existem opções de entrega para este endereço.", message: "Atualmente não temos opções de entregar para o seu endereço, tente novamente mais tarde")

    quotations = MiniTest::Mock.new
    quotations.expect(:to_a, [])

    Quotations.stub(:new, quotations) do
      post "/quote?token=#{shop.token}", shipping_zip: "12946636", products: [{ quantity: 1 }]

      response.status.must_equal(400)
      response.body.must_equal({ error: "Atualmente não temos opções de entregar para o seu endereço, tente novamente mais tarde" }.to_json)

      shop.reload.shipping_errors.size.must_equal(1)
      shop.reload.shipping_errors[0].message.must_equal("Não existem opções de entrega para este endereço.")
    end

    assert quotations.verify
  end

  test "returns all available quotations" do
    stub_correios

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

  test "returns all available quotations for all packages" do
    stub_correios
    stub_correios_for_loja1
    stub_correios_for_loja2

    shop = create_shop(
      forward_to_correios: true,
      correios_code: "correioscode",
      correios_password: "correiosp@ss"
    )

    child_1 = create_shop(
      name: "Loja 1",
      forward_to_correios: true,
      correios_code: "loja1code",
      correios_password: "loja1pass",
      marketplace_id: shop.id,
      marketplace_tag: "child-1"
    )

    child_2 = create_shop(
      name: "Loja 2",
      forward_to_correios: true,
      correios_code: "loja2code",
      correios_password: "loja2pass",
      marketplace_id: shop.id,
      marketplace_tag: "child-2"
    )

    products = [
      { width: 8.0, height: 3.0, length: 15.0, quantity: 1, tags: ["camiseta", "child-1"] },
      { width: 7.0, height: 2.0, length: 14.0, quantity: 1, tags: ["meia"] },
      { width: 9.0, height: 4.0, length: 16.0, quantity: 1, tags: ["calca", "child-2"] }
    ]

    post "/quote", token: shop.token, origin_zip: "03320000", shipping_zip: "80035120", products: products

    assert_equal 200, status

    quotations = JSON.load(body)

    assert_equal 2, quotations.size
    assert_equal 54.9, quotations[0]["price"]
    assert_equal 7, quotations[0]["deadline"]
    assert_equal 78.0, quotations[1]["price"]
    assert_equal 1, quotations[1]["deadline"]
  end

  def create_shop(attributes = {})
    Shop.create!({ name: 'Loja', token: "a1b2c3" }.merge(attributes))
  end

  def stub_correios
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

  def stub_correios_for_loja1
    stub_request(:post, "http://ws.correios.com.br/calculador/CalcPrecoPrazo.asmx").
      with(body: Rails.root.join("test/fixtures/calc_preco_prazo-child1.request.xml").read.strip).
      to_return(status: 200,
        body: Rails.root.join("test/fixtures/calc_preco_prazo-child1.response.xml").read,
        headers: { "Content-Type" => "text/xml; charset=utf-8" })
  end

  def stub_correios_for_loja2
    stub_request(:post, "http://ws.correios.com.br/calculador/CalcPrecoPrazo.asmx").
      with(body: Rails.root.join("test/fixtures/calc_preco_prazo-child2.request.xml").read.strip).
      to_return(status: 200,
        body: Rails.root.join("test/fixtures/calc_preco_prazo-child2.response.xml").read,
        headers: { "Content-Type" => "text/xml; charset=utf-8" })
  end
end
