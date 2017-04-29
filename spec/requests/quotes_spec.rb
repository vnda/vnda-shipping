require 'rails_helper'

RSpec.describe "Quotes" do
  before { Timecop.freeze(2017, 3, 27, 17, 54, 55) }
  after { Timecop.return }

  it "correios return unauthorized if no token" do
    post "/quote", token: nil


    assert_equal 401, status
  end

  it "correios return 400 if no mandatory parameters" do
    shop = create_shop

    post "/quote", token: shop.token
    assert_equal 400, status
  end

  it "generates a new error message when no quotations" do
    shop = create_shop

    package_quotations = double("package_quotations")
    expect(package_quotations).to receive(:to_h).and_return(total_quotations: 0)

    expect(PackageQuotations).to receive(:new).and_return(package_quotations)

    post "/quote?token=#{shop.token}", package_prefix: "A1B2C3", shipping_zip: "12946636", products: [{ quantity: 1 }]

    expect(response.status).to eq(400)
    expect(response.body).to eq({ error: "Não existem opções de entrega para este endereço." }.to_json)

    expect(shop.reload.shipping_errors.size).to eq(1)
    expect(shop.reload.shipping_errors[0].message).to eq("Não existem opções de entrega para este endereço.")
  end

  it "returns a friendly error message when no quotations" do
    shop = create_shop
    shop.shipping_friendly_errors.create!(rule: "Não existem opções de entrega para este endereço.", message: "Atualmente não temos opções de entregar para o seu endereço, tente novamente mais tarde")

    package_quotations = double("package_quotations")
    expect(package_quotations).to receive(:to_h).and_return(total_quotations: 0)

    expect(PackageQuotations).to receive(:new).and_return(package_quotations)

    post "/quote?token=#{shop.token}", package_prefix: "A1B2C3", shipping_zip: "12946636", products: [{ quantity: 1 }]

    expect(response.status).to eq(400)
    expect(response.body).to eq({ error: "Atualmente não temos opções de entregar para o seu endereço, tente novamente mais tarde" }.to_json)

    expect(shop.reload.shipping_errors.size).to eq(1)
    expect(shop.reload.shipping_errors[0].message).to eq("Não existem opções de entrega para este endereço.")
  end

  it "returns all available quotations for a single package" do
    stub_correios

    shop = create_shop(
      forward_to_correios: true,
      correios_code: "correioscode",
      correios_password: "correiosp@ss",
      zip: "03320000"
    )

    post "/quote", token: shop.token, cart_id: 1, package_prefix: "A1B2C3",
      shipping_zip: "80035120", products: [{ width: 7.0, height: 2.0,
        length: 14.0, quantity: 1, sku: "A1" }]

    assert_equal 200, status

    quotations = JSON.load(body)
    assert_equal ["A1B2C3-01"], quotations.keys
    assert_equal 2, quotations["A1B2C3-01"].size

    assert_equal "Normal", quotations["A1B2C3-01"][0]["name"]
    assert_equal 18.3, quotations["A1B2C3-01"][0]["price"]
    assert_equal 7, quotations["A1B2C3-01"][0]["deadline"]
    assert_equal "pac", quotations["A1B2C3-01"][0]["slug"]
    assert_equal "Normal", quotations["A1B2C3-01"][0]["delivery_type"]
    assert_equal "normal", quotations["A1B2C3-01"][0]["delivery_type_slug"]
    assert_equal "Correios", quotations["A1B2C3-01"][0]["deliver_company"]
    assert_nil quotations["A1B2C3-01"][0]["notice"]
    assert_nil quotations["A1B2C3-01"][0]["quotation_id"]

    assert_equal "Expressa", quotations["A1B2C3-01"][1]["name"]
    assert_equal 26.0, quotations["A1B2C3-01"][1]["price"]
    assert_equal 1, quotations["A1B2C3-01"][1]["deadline"]
    assert_equal "sedex", quotations["A1B2C3-01"][1]["slug"]
    assert_equal "Expressa", quotations["A1B2C3-01"][1]["delivery_type"]
    assert_equal "expressa", quotations["A1B2C3-01"][1]["delivery_type_slug"]
    assert_equal "Correios", quotations["A1B2C3-01"][1]["deliver_company"]
    assert_nil quotations["A1B2C3-01"][1]["notice"]
    assert_nil quotations["A1B2C3-01"][1]["quotation_id"]
  end

  it "returns all available quotations for all packages" do
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
      marketplace_tag: "child-2",
      zip: "03320000"
    )

    products = [
      { width: 8.0, height: 3.0, length: 15.0, quantity: 1, sku: "A1", tags: ["camiseta", "child-1"] },
      { width: 7.0, height: 2.0, length: 14.0, quantity: 1, sku: "A2", tags: ["meia"] },
      { width: 9.0, height: 4.0, length: 16.0, quantity: 1, sku: "A3", tags: ["calca", "child-2"] }
    ]

    post "/quote", token: shop.token, package_prefix: "A1B2C3", cart_id: 1,
      shipping_zip: "80035120", products: products

    assert_equal 200, status

    quotations = JSON.load(body)

    assert_equal ["A1B2C3-01", "A1B2C3-02", "A1B2C3-03"], quotations.keys

    assert_equal 2, quotations["A1B2C3-01"].size
    assert_equal 18.3, quotations["A1B2C3-01"][0]["price"]
    assert_equal 7, quotations["A1B2C3-01"][0]["deadline"]
    assert_equal 26.0, quotations["A1B2C3-01"][1]["price"]
    assert_equal 1, quotations["A1B2C3-01"][1]["deadline"]

    assert_equal 2, quotations["A1B2C3-02"].size
    assert_equal 16.3, quotations["A1B2C3-02"][0]["price"]
    assert_equal 9, quotations["A1B2C3-02"][0]["deadline"]
    assert_equal 27.0, quotations["A1B2C3-02"][1]["price"]
    assert_equal 1, quotations["A1B2C3-02"][1]["deadline"]

    assert_equal 2, quotations["A1B2C3-03"].size
    assert_equal 17.3, quotations["A1B2C3-03"][0]["price"]
    assert_equal 8, quotations["A1B2C3-03"][0]["deadline"]
    assert_equal 26.5, quotations["A1B2C3-03"][1]["price"]
    assert_equal 1, quotations["A1B2C3-03"][1]["deadline"]
  end

  it "increments deadline for all quotations" do
    stub_correios

    shop = create_shop(
      forward_to_correios: true,
      correios_code: "correioscode",
      correios_password: "correiosp@ss",
      zip: "03320000"
    )

    post "/quote", token: shop.token, cart_id: 1, package_prefix: "A1B2C3",
      shipping_zip: "80035120", products: [{ width: 7.0, height: 2.0,
        length: 14.0, quantity: 1, sku: "A1", handling_days: 10 }]

    expect(status).to eq(200)

    quotations = JSON.load(body)

    expect(quotations.keys).to eq(["A1B2C3-01"])
    expect(quotations["A1B2C3-01"].size).to eq(2)

    expect(quotations["A1B2C3-01"][0]["deadline"]).to eq(17)
    expect(quotations["A1B2C3-01"][1]["deadline"]).to eq(11)
  end

  def create_shop(attributes = {})
    Shop.create!({ name: 'Loja', token: "a1b2c3", zip: "03320000" }.merge(attributes))
  end

  def stub_correios
    stub_request(:get, "http://ws.correios.com.br/calculador/CalcPrecoPrazo.asmx?WSDL").
      to_return(status: 200,
        body: Rails.root.join("spec/fixtures/calc_preco_prazo.wsdl").read,
        headers: { "Content-Type" => "text/xml; charset=utf-8" })

    stub_request(:post, "http://ws.correios.com.br/calculador/CalcPrecoPrazo.asmx").
      with(body: Rails.root.join("spec/fixtures/calc_preco_prazo.request.xml").read.strip).
      to_return(status: 200,
        body: Rails.root.join("spec/fixtures/calc_preco_prazo.response.xml").read,
        headers: { "Content-Type" => "text/xml; charset=utf-8" })
  end

  def stub_correios_for_loja1
    stub_request(:post, "http://ws.correios.com.br/calculador/CalcPrecoPrazo.asmx").
      with(body: Rails.root.join("spec/fixtures/calc_preco_prazo-child1.request.xml").read.strip).
      to_return(status: 200,
        body: Rails.root.join("spec/fixtures/calc_preco_prazo-child1.response.xml").read,
        headers: { "Content-Type" => "text/xml; charset=utf-8" })
  end

  def stub_correios_for_loja2
    stub_request(:post, "http://ws.correios.com.br/calculador/CalcPrecoPrazo.asmx").
      with(body: Rails.root.join("spec/fixtures/calc_preco_prazo-child2.request.xml").read.strip).
      to_return(status: 200,
        body: Rails.root.join("spec/fixtures/calc_preco_prazo-child2.response.xml").read,
        headers: { "Content-Type" => "text/xml; charset=utf-8" })
  end
end
