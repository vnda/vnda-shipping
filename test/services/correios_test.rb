require "test_helper"

class CorreiosTest < ActiveSupport::TestCase
  test "use only enabled services" do
    stub_request(:get, "http://ws.correios.com.br/calculador/CalcPrecoPrazo.asmx?WSDL").
      to_return(status: 200,
        body: Rails.root.join("test/fixtures/calc_preco_prazo.wsdl").read,
        headers: { "Content-Type" => "text/xml; charset=utf-8" })

    stub_request(:post, "http://ws.correios.com.br/calculador/CalcPrecoPrazo.asmx").
      with(body: request_fixture).
      to_return(status: 200, body: response_fixture)

    shop = create_shop
    shop.methods.first.toggle!(:enabled)

    quotations = Correios.new(shop, Rails.logger).quote(
      cart_id: 1,
      package: "A1B2C3",
      shipping_zip: "90540140",
      products: [
        { width: 7.0, height: 2.0, length: 14.0, quantity: 1, sku: "A1", tags: ["camiseta"] }
      ]
    )

    assert_equal 1, quotations.size

    assert_instance_of Quotation, quotations[0]
    assert_equal "Expressa", quotations[0].name
    assert_equal 26.8, quotations[0].price
    assert_equal 1, quotations[0].deadline
    assert_equal "sedex", quotations[0].slug
    assert_equal "Expressa", quotations[0].delivery_type
    assert_equal "Correios", quotations[0].deliver_company
    assert_nil quotations[0].quotation_id
    assert_equal "expressa", quotations[0].delivery_type_slug
    assert_nil quotations[0].notice
  end

  test "fallback_quote" do
    create_fallback_shop

    stub_request(:get, "http://ws.correios.com.br/calculador/CalcPrecoPrazo.asmx?WSDL").
      to_return(status: 200,
        body: Rails.root.join("test/fixtures/calc_preco_prazo.wsdl").read,
        headers: { "Content-Type" => "text/xml; charset=utf-8" })

    stub_request(:post, "http://ws.correios.com.br/calculador/CalcPrecoPrazo.asmx").
      with(body: "<?xml version=\"1.0\" encoding=\"UTF-8\"?><env:Envelope xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:tns=\"http://tempuri.org/\" xmlns:env=\"http://schemas.xmlsoap.org/soap/envelope/\"><env:Body><tns:CalcPrecoPrazo><tns:nCdEmpresa>code</tns:nCdEmpresa><tns:sDsSenha>pass</tns:sDsSenha><tns:nCdServico>41106,40010</tns:nCdServico><tns:sCepOrigem>03320000</tns:sCepOrigem><tns:sCepDestino>90540140</tns:sCepDestino><tns:nVlPeso>0.0</tns:nVlPeso><tns:nCdFormato>1</tns:nCdFormato><tns:nVlComprimento>16</tns:nVlComprimento><tns:nVlAltura>6</tns:nVlAltura><tns:nVlLargura>11</tns:nVlLargura><tns:nVlDiametro>0</tns:nVlDiametro><tns:sCdMaoPropria>N</tns:sCdMaoPropria><tns:sCdAvisoRecebimento>N</tns:sCdAvisoRecebimento><tns:nVlValorDeclarado>17.0</tns:nVlValorDeclarado></tns:CalcPrecoPrazo></env:Body></env:Envelope>",
        headers: { "Content-Type" => "text/xml;charset=UTF-8", "Soapaction"=>"\"http://tempuri.org/CalcPrecoPrazo\"" }).
      to_timeout

    shop = create_shop
    quotations = Correios.new(shop, Rails.logger).quote(
      cart_id: 1,
      package: "A1B2C3",
      shipping_zip: "90540140",
      products: [
        { width: 7.0, height: 2.0, length: 14.0, quantity: 1, sku: "A1", tags: ["camiseta"] }
      ]
    )

    assert_equal 2, quotations.size

    assert_instance_of Quotation, quotations[0]
    assert_equal "Normal", quotations[0].name
    assert_equal 15, quotations[0].price
    assert_equal 4, quotations[0].deadline
    assert_equal "pac-varejo", quotations[0].slug
    assert_equal "Normal", quotations[0].delivery_type
    assert_nil quotations[0].deliver_company
    assert_nil quotations[0].quotation_id
    assert_equal "normal", quotations[0].delivery_type_slug
    assert_nil quotations[0].notice

    assert_instance_of Quotation, quotations[1]
    assert_equal "Expressa", quotations[1].name
    assert_equal 30, quotations[1].price
    assert_equal 2, quotations[1].deadline
    assert_equal "sedex-varejo", quotations[1].slug
    assert_equal "Expressa", quotations[1].delivery_type
    assert_nil quotations[1].deliver_company
    assert_nil quotations[1].quotation_id
    assert_equal "expressa", quotations[1].delivery_type_slug
    assert_nil quotations[1].notice
  end

  test "#deadline_business_day for sedex" do
    Timecop.freeze(2017, 4, 04, 17, 54, 55) do
      shop = create_shop

      correios = Correios.new(shop, Rails.logger)

      assert_equal 1, correios.deadline_business_day(40000, 1)
      assert_equal 2, correios.deadline_business_day(40000, 2)
      assert_equal 3, correios.deadline_business_day(40000, 3)
      assert_equal 4, correios.deadline_business_day(40000, 4)

      assert_equal 6, correios.deadline_business_day(40000, 5)
      assert_equal 7, correios.deadline_business_day(40000, 6)
      assert_equal 8, correios.deadline_business_day(40000, 7)
      assert_equal 9, correios.deadline_business_day(40000, 8)
      assert_equal 10, correios.deadline_business_day(40000, 9)
      assert_equal 11, correios.deadline_business_day(40000, 10)

      assert_equal 13, correios.deadline_business_day(40000, 11)
      assert_equal 14, correios.deadline_business_day(40000, 12)
      assert_equal 15, correios.deadline_business_day(40000, 13)
      assert_equal 16, correios.deadline_business_day(40000, 14)
      assert_equal 17, correios.deadline_business_day(40000, 15)
      assert_equal 18, correios.deadline_business_day(40000, 16)

      assert_equal 20, correios.deadline_business_day(40000, 17)
      assert_equal 21, correios.deadline_business_day(40000, 18)
      assert_equal 22, correios.deadline_business_day(40000, 19)
      assert_equal 23, correios.deadline_business_day(40000, 20)
    end
  end

  test "#deadline_business_day for pac" do
    Timecop.freeze(2017, 4, 04, 17, 54, 55) do
      shop = create_shop
      correios = Correios.new(shop, Rails.logger)

      assert_equal 1, correios.deadline_business_day(41000, 1)
      assert_equal 2, correios.deadline_business_day(41000, 2)
      assert_equal 3, correios.deadline_business_day(41000, 3)

      assert_equal 6, correios.deadline_business_day(41000, 4)
      assert_equal 7, correios.deadline_business_day(41000, 5)
      assert_equal 8, correios.deadline_business_day(41000, 6)
      assert_equal 9, correios.deadline_business_day(41000, 7)
      assert_equal 10, correios.deadline_business_day(41000, 8)

      assert_equal 13, correios.deadline_business_day(41000, 9)
      assert_equal 14, correios.deadline_business_day(41000, 10)
      assert_equal 15, correios.deadline_business_day(41000, 11)
      assert_equal 16, correios.deadline_business_day(41000, 12)
      assert_equal 17, correios.deadline_business_day(41000, 13)

      assert_equal 20, correios.deadline_business_day(41000, 14)
      assert_equal 21, correios.deadline_business_day(41000, 15)
      assert_equal 22, correios.deadline_business_day(41000, 16)
      assert_equal 23, correios.deadline_business_day(41000, 17)
      assert_equal 24, correios.deadline_business_day(41000, 18)

      assert_equal 27, correios.deadline_business_day(41000, 19)
      assert_equal 28, correios.deadline_business_day(41000, 20)
    end
  end

  def create_shop(attributes = {})
    Shop.create!(attributes.reverse_merge(
      name: "Loja",
      forward_to_correios: true,
      correios_code: "code",
      correios_password: "pass",
      zip: "03320000"
    ))
  end

  def create_fallback_shop
    shop = Shop.create!(name: "fallback", zip: "03320000")

    normal_method = shop.methods.create!(
      name: "Normal",
      slug: "normal",
      description: "PAC Varejo CSV 0.0 até 30",
      enabled: true,
      min_weigth: 0,
      max_weigth: 30,
      delivery_type_id: shop.delivery_types.where(name: "Normal").first.id,
      data_origin: "local"
    )
    normal_method.zip_rules.create!(range: 90000000..99999999, price: 15.0, deadline: 4)

    express_method = shop.methods.create!(
      name: "Expressa",
      description: "SEDEX Varejo CSV 0.3 até 0.5",
      enabled: true,
      min_weigth: 0,
      max_weigth: 30,
      delivery_type_id: shop.delivery_types.where(name: "Expressa").first.id,
      data_origin: "local"
    )
    express_method.zip_rules.create!(range: 90000000..99999999, price: 30.0, deadline: 2)
  end
end
