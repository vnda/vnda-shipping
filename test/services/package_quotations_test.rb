require "test_helper"

class PackageQuotationsTest < ActiveSupport::TestCase
  test "calculates for multiple packages" do
    # stub_request(:get, "http://ws.correios.com.br/calculador/CalcPrecoPrazo.asmx?WSDL").
    #   to_return(status: 200,
    #     body: Rails.root.join("test/fixtures/calc_preco_prazo.wsdl").read,
    #     headers: { "Content-Type" => "text/xml; charset=utf-8" })

    # stub_request(:post, "http://ws.correios.com.br/calculador/CalcPrecoPrazo.asmx").
    #   with({ body: Rails.root.join("test/fixtures/calc_preco_prazo-child-1.request.xml").read.strip }, { body: Rails.root.join("test/fixtures/calc_preco_prazo.request.xml").read.strip }).
    #   to_return(status: 200,
    #     body: Rails.root.join("test/fixtures/calc_preco_prazo.response.xml").read,
    #     headers: { "Content-Type" => "text/xml; charset=utf-8" })

    marketplace = create_shop(
      forward_to_correios: true,
      correios_code: "correioscode",
      correios_password: "correiosp@ss"
    )

    child_1 = create_shop(
      name: "Loja 1",
      forward_to_correios: true,
      correios_code: "loja1code",
      correios_password: "loja1p@ss",
      marketplace_id: marketplace.id,
      marketplace_tag: "child-1"
    )

    child_2 = create_shop(
      name: "Loja 2",
      forward_to_correios: true,
      correios_code: "loja2code",
      correios_password: "loja2p@ss",
      marketplace_id: marketplace.id,
      marketplace_tag: "child-2"
    )

    products = [
      { width: 7.0, height: 2.0, length: 14.0, quantity: 1, tags: ["camiseta", "child-1"] },
      { width: 2.0, height: 1.0, length: 6.0, quantity: 1, tags: ["meia"] },
      { width: 9.0, height: 5.0, length: 24.0, quantity: 1, tags: ["calca", "child-2"] }
    ]

    child_1_quotations = [express_quotation(price: 10, deadline: 10), normal_quotation(price: 5, deadline: 20)]
    marketplace_quotations = [express_quotation(price: 9, deadline: 10), normal_quotation(price: 6, deadline: 19)]
    child_2_quotations = [express_quotation(price: 8, deadline: 11), normal_quotation(price: 7, deadline: 15)]

    quotations_mock = MiniTest::Mock.new
    quotations_mock.expect(:to_a, child_1_quotations)
    quotations_mock.expect(:to_a, marketplace_quotations)
    quotations_mock.expect(:to_a, child_2_quotations)

    quotations_class_mock = MiniTest::Mock.new
    quotations_class_mock.expect(:new, quotations_mock, [child_1, { origin_zip: "03320000", products: [products[0]], shipping_zip: "80035120" }])
    quotations_class_mock.expect(:new, quotations_mock, [marketplace, { origin_zip: "03320000", products: [products[1]], shipping_zip: "80035120" }])
    quotations_class_mock.expect(:new, quotations_mock, [child_2, { origin_zip: "03320000", products: [products[2]], shipping_zip: "80035120" }])

    quotations = PackageQuotations.
      new(marketplace, origin_zip: "03320000", shipping_zip: "80035120", products: products).
      to_a(quotations_class_mock)

    assert_equal 2, quotations.size

    assert_equal "expressa", quotations[0].slug
    assert_equal 27, quotations[0].price
    assert_equal 11, quotations[0].deadline

    assert_equal "normal", quotations[1].slug
    assert_equal 18, quotations[1].price
    assert_equal 20, quotations[1].deadline
  end

  def create_shop(attributes = {})
    Shop.create!({ name: 'Loja', token: "a1b2c3" }.merge(attributes))
  end

  def express_quotation(attributes)
    Quotation.new({
      name: "Expressa",
      slug: "expressa",
      delivery_type: "Expressa",
      deliver_company: "",
      notice: "",
      cotation_id: nil
    }.merge(attributes))
  end

  def normal_quotation(attributes)
    Quotation.new({
      name: "Normal",
      slug: "normal",
      delivery_type: "Normal",
      deliver_company: "",
      notice: "",
      cotation_id: nil
    }.merge(attributes))
  end
end
