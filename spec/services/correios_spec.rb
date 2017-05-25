require "rails_helper"

RSpec.describe Correios do
  before { Timecop.travel(2017, 4, 28, 22, 23, 24) }
  after { Timecop.return }

  it "use only enabled services" do
    stub_request(:get, "http://ws.correios.com.br/calculador/CalcPrecoPrazo.asmx?WSDL").
      to_return(status: 200,
        body: Rails.root.join("spec/fixtures/calc_preco_prazo.wsdl").read,
        headers: { "Content-Type" => "text/xml; charset=utf-8" })

    stub_request(:post, "http://ws.correios.com.br/calculador/CalcPrecoPrazo.asmx").
      with(body: request_fixture).
      to_return(status: 200, body: response_fixture)

    shop = create_shop
    shop.methods.where(slug: "pac").first.toggle!(:enabled)

    quotations = Correios.new(shop, Rails.logger).quote(
      cart_id: 1,
      package: "foo",
      shipping_zip: "90540140",
      products: [{
        width: 7.0,
        height: 2.0,
        length: 14.0,
        quantity: 1,
        sku: "A1",
        price: 100
      }]
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

  it "#declared_value" do
    shop = create_shop(declare_value: true)

    value = Correios.new(shop, Rails.logger).declared_value(
      cart_id: 1,
      package: "foo",
      shipping_zip: "90540140",
      products: [{
        width: 7.0,
        height: 2.0,
        length: 14.0,
        quantity: 2,
        sku: "A1",
        price: 100
      }]
    )

    assert_equal 200.0, value
  end

  it "fallback_quote" do
    create_fallback_shop

    stub_request(:get, "http://ws.correios.com.br/calculador/CalcPrecoPrazo.asmx?WSDL").
      to_return(status: 200,
        body: Rails.root.join("spec/fixtures/calc_preco_prazo.wsdl").read,
        headers: { "Content-Type" => "text/xml; charset=utf-8" })

    stub_request(:post, "http://ws.correios.com.br/calculador/CalcPrecoPrazo.asmx").
      with(body: "<?xml version=\"1.0\" encoding=\"UTF-8\"?><env:Envelope xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:tns=\"http://tempuri.org/\" xmlns:env=\"http://schemas.xmlsoap.org/soap/envelope/\"><env:Body><tns:CalcPrecoPrazo><tns:nCdEmpresa>code</tns:nCdEmpresa><tns:sDsSenha>pass</tns:sDsSenha><tns:nCdServico>04669,04162</tns:nCdServico><tns:sCepOrigem>03320000</tns:sCepOrigem><tns:sCepDestino>90540140</tns:sCepDestino><tns:nVlPeso>0.0</tns:nVlPeso><tns:nCdFormato>1</tns:nCdFormato><tns:nVlComprimento>16</tns:nVlComprimento><tns:nVlAltura>6</tns:nVlAltura><tns:nVlLargura>11</tns:nVlLargura><tns:nVlDiametro>0</tns:nVlDiametro><tns:sCdMaoPropria>N</tns:sCdMaoPropria><tns:sCdAvisoRecebimento>N</tns:sCdAvisoRecebimento><tns:nVlValorDeclarado>17.0</tns:nVlValorDeclarado></tns:CalcPrecoPrazo></env:Body></env:Envelope>",
        headers: { "Content-Type" => "text/xml;charset=UTF-8", "Soapaction"=>"\"http://tempuri.org/CalcPrecoPrazo\"" }).
      to_timeout

    shop = create_shop
    quotations = Correios.new(shop, Rails.logger).quote(
      cart_id: 1,
      package: "A1B2C3",
      shipping_zip: "90540140",
      products: [
        { width: 7.0, height: 2.0, length: 14.0, quantity: 1, sku: "A1" }
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

  it "#deadline_business_day for sedex" do
    Timecop.freeze(2017, 4, 4, 17, 54, 55) do
      shop = create_shop
      shipping_method = shop.methods.where(name: "Expressa").first

      correios = Correios.new(shop, Rails.logger)

      expect(correios.deadline_business_day(shipping_method, 1)).to eq(1)
      expect(correios.deadline_business_day(shipping_method, 2)).to eq(2)
      expect(correios.deadline_business_day(shipping_method, 3)).to eq(3)
      expect(correios.deadline_business_day(shipping_method, 4)).to eq(4)

      expect(correios.deadline_business_day(shipping_method, 5)).to eq(6)
      expect(correios.deadline_business_day(shipping_method, 6)).to eq(7)
      expect(correios.deadline_business_day(shipping_method, 7)).to eq(8)
      expect(correios.deadline_business_day(shipping_method, 8)).to eq(9)
      expect(correios.deadline_business_day(shipping_method, 9)).to eq(10)
      expect(correios.deadline_business_day(shipping_method, 10)).to eq(11)

      expect(correios.deadline_business_day(shipping_method, 11)).to eq(13)
      expect(correios.deadline_business_day(shipping_method, 12)).to eq(14)
      expect(correios.deadline_business_day(shipping_method, 13)).to eq(15)
      expect(correios.deadline_business_day(shipping_method, 14)).to eq(16)
      expect(correios.deadline_business_day(shipping_method, 15)).to eq(17)
      expect(correios.deadline_business_day(shipping_method, 16)).to eq(18)

      expect(correios.deadline_business_day(shipping_method, 17)).to eq(20)
      expect(correios.deadline_business_day(shipping_method, 18)).to eq(21)
      expect(correios.deadline_business_day(shipping_method, 19)).to eq(22)
      expect(correios.deadline_business_day(shipping_method, 20)).to eq(23)
    end
  end

  it "#deadline_business_day for pac" do
    Timecop.freeze(2017, 4, 4, 17, 54, 55) do
      shop = create_shop
      shipping_method = shop.methods.where(name: "Normal").first

      correios = Correios.new(shop, Rails.logger)

      expect(correios.deadline_business_day(shipping_method, 1)).to eq(1)
      expect(correios.deadline_business_day(shipping_method, 2)).to eq(2)
      expect(correios.deadline_business_day(shipping_method, 3)).to eq(3)

      expect(correios.deadline_business_day(shipping_method, 4)).to eq(6)
      expect(correios.deadline_business_day(shipping_method, 5)).to eq(7)
      expect(correios.deadline_business_day(shipping_method, 6)).to eq(8)
      expect(correios.deadline_business_day(shipping_method, 7)).to eq(9)
      expect(correios.deadline_business_day(shipping_method, 8)).to eq(10)

      expect(correios.deadline_business_day(shipping_method, 9)).to eq(13)
      expect(correios.deadline_business_day(shipping_method, 10)).to eq(14)
      expect(correios.deadline_business_day(shipping_method, 11)).to eq(15)
      expect(correios.deadline_business_day(shipping_method, 12)).to eq(16)
      expect(correios.deadline_business_day(shipping_method, 13)).to eq(17)

      expect(correios.deadline_business_day(shipping_method, 14)).to eq(20)
      expect(correios.deadline_business_day(shipping_method, 15)).to eq(21)
      expect(correios.deadline_business_day(shipping_method, 16)).to eq(22)
      expect(correios.deadline_business_day(shipping_method, 17)).to eq(23)
      expect(correios.deadline_business_day(shipping_method, 18)).to eq(24)

      expect(correios.deadline_business_day(shipping_method, 19)).to eq(27)
      expect(correios.deadline_business_day(shipping_method, 20)).to eq(28)
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
