require "rails_helper"

RSpec.describe Quotations, "tnt" do
  it "returns quotations using tnt" do
    shop = create_shop(
      forward_to_tnt: true,
      tnt_email: "foo@bar.com",
      tnt_cnpj: "12345678901234",
      tnt_ie: "12345",
      tnt_delivery_type: "Normal",
      tnt_service_id: 1,
      zip: "03320000"
    )

    quotations = new_tnt_quotations(shop)
    assert_equal 1, quotations.size

    assert_instance_of Quotation, quotations[0]
    assert_equal "TNT", quotations[0].name
    assert_equal BigDecimal.new("21.26"), quotations[0].price
    assert_equal 1, quotations[0].deadline
    assert_equal "tnt", quotations[0].slug
    assert_equal "Normal", quotations[0].delivery_type
    assert_equal "TNT", quotations[0].deliver_company
    assert_equal "normal", quotations[0].delivery_type_slug
    assert_nil quotations[0].notice
  end

  it "increments returned deadline for tnt quotations" do
    shop = create_shop(
      forward_to_tnt: true,
      tnt_email: "foo@bar.com",
      tnt_cnpj: "12345678901234",
      tnt_ie: "12345",
      tnt_delivery_type: "Normal",
      tnt_service_id: 1,
      zip: "03320000"
    )

    quotations = new_tnt_quotations(shop, products: [new_product(handling_days: 10)])
    expect(quotations.size).to eq(1)

    expect(quotations[0].deadline).to eq(11)
  end

  def create_shop(attributes = {})
    Shop.create!(attributes.reverse_merge(name: 'Loja', token: "a1b2c3", zip: "03320000"))
  end

  def new_product(params = {})
    params.reverse_merge(width: 7.0, height: 2.0, length: 14.0, quantity: 1, sku: "A1")
  end

  def new_tnt_quotations(shop, params = {})
    stub_tnt_requests

    params = params.reverse_merge(
      cart_id: 1,
      package: "A1B2C3-1",
      shipping_zip: "80035120",
      products: [{ width: 7.0, height: 2.0, length: 14.0, quantity: 1, sku: "A1" }]
    )

    Quotations.new(shop, params, Rails.logger).to_a
  end

  def stub_tnt_requests
    stub_request(:get, "http://ws.tntbrasil.com.br/servicos/CalculoFrete?wsdl").
      to_return(status: 200,
        body: Rails.root.join("spec/fixtures/tnt_wsdl.xml").read,
        headers: { "Content-Type" => "text/xml; charset=utf-8" })

    stub_request(:post, "http://ws.tntbrasil.com.br/servicos/CalculoFrete").
      with(body: Rails.root.join("spec/fixtures/tnt_request.xml").read.strip).
      to_return(status: 200,
        body: Rails.root.join("spec/fixtures/tnt_response.xml").read,
        headers: { "Content-Type" => "text/xml; charset=utf-8" })
  end
end
