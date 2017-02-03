require 'test_helper'

describe Shop do
  let(:shop_params) { { id: 1, name: "Loja Teste"} }
  let(:shop) { Shop.new(shop_params) }

  it "is valid with valid params" do
    shop.must_be :valid?
  end

  it "is invalid without a name" do
    shop_params.delete :name

    shop.wont_be :valid?
    shop.errors[:name].must_be :present?
  end

  it "is invalid if axado is checked and axado_token is empty" do
    shop_params.merge!( {forward_to_axado: true})

    shop.wont_be :valid?
    shop.errors[:axado_token].must_be :present?
  end

  it "is valid if forward_to_axado is checked and axado_token is present" do
    shop_params.merge!( {forward_to_axado: true, axado_token: "12345678"})

    shop.must_be :valid?
  end

  it "is invalid if forward_to_correios is checked and correios_code or correios_password is empty" do
    shop_params.merge!( {forward_to_correios: true})

    shop.wont_be :valid?
    shop.errors[:correios_password].must_be :present?
    shop.errors[:correios_code].must_be :present?
  end

  it "is valid if correios is checked and correios_token is present" do
    shop_params.merge!( {forward_to_correios: true, correios_code: "12345678", correios_password: "abcdef"})

    shop.must_be :valid?
  end

  it "creates default delivery types" do
    shop.delivery_types.count.must_equal 0
    shop.save!
    shop.delivery_types.count.must_equal 2
  end

  it "does not create correios shipping methods" do
    shop.forward_to_correios = false

    shop.save!
    shop.methods.count.must_equal 0
  end

  it "creates correios shipping methods" do
    shop.forward_to_correios = true
    shop.correios_code = "a"
    shop.correios_password = "b"

    shop.methods.count.must_equal 0
    shop.save!
    shop.methods.count.must_equal 2
  end

  describe "before creating" do
    it "generates a token" do
      shop.token.must_be :nil?
      shop.save!
      shop.token.wont_be :nil?
    end
  end

  describe "#volume_for" do
    it "returns zero if no items" do
      volume = shop.volume_for([])

      volume.must_equal(0)
    end

    it "returns volume for all given items" do
      items = [
        { width: 7.0, height: 2.0, length: 14.0, quantity: 1 },
        { width: 11.0, height: 2.0, length: 16.0, quantity: 2 }
      ]
      volume = shop.volume_for(items)

      volume.must_equal(900)
    end
  end

  describe "#quote" do
    let(:shop) { Shop.create!(shop_params.merge(forward_to_correios: true, correios_code: "correioscode", correios_password: "correiosp@ss")) }

    it "raises an error if no valid parameters" do
      proc { shop.quote({}) }.must_raise(BadParams)
    end

    it "generates a new quotation for local" do
      shop.save!

      delivery_type = shop.delivery_types.create!(
        name: "Retirar na Loja",
        enabled: true
      )

      shipping_method = shop.methods.create!(
        name: "Retirar na Loja",
        description: "Retirar na Loja",
        express: false,
        enabled: true,
        min_weigth: 0,
        max_weigth: 100,
        delivery_type_id: delivery_type.id,
        data_origin: "local"
      )

      shipping_method.zip_rules.create!(
        min: 90000001,
        max: 92000000,
        price: 10,
        deadline: 1
      )

      items = [
        { width: 7.0, height: 2.0, length: 14.0, quantity: 1 },
        { width: 11.0, height: 2.0, length: 16.0, quantity: 2 }
      ]
      quotations = shop.quote(shipping_zip: "90540-140", products: items)

      quotations.size.must_equal(1)
      quotations[0].must_be_instance_of(Quotation)
      quotations[0].cotation_id.must_equal("")
      quotations[0].deadline.must_equal(1)
      quotations[0].deliver_company.must_equal("")
      quotations[0].delivery_type.must_equal("Retirar na Loja")
      quotations[0].delivery_type_slug.must_equal("retirar-na-loja")
      quotations[0].name.must_equal("Retirar na Loja")
      quotations[0].notice.must_equal("")
      quotations[0].price.must_equal(10.0)
      quotations[0].slug.must_equal("retirar-na-loja")
    end

    describe "for google maps" do
      before do
        shop.save!

        @shipping_method = shop.methods.create!(
          name: "Canoas",
          description: "Canoas",
          express: false,
          enabled: true,
          min_weigth: 0,
          max_weigth: 100,
          delivery_type_id: shop.delivery_types.first.id,
          data_origin: "google_maps",
          mid: "a1b2c3"
        )

        kml = Rails.root.join("test/fixtures/vnda-old.kml").read
        @shipping_method.build_or_update_map_rules_from(Nokogiri::XML(kml))
      end

      it "generates a new quotation" do
        stub_request(:get, "https://maps.googleapis.com/maps/api/geocode/json?address=90540-140&key&region=br").
          to_return(status: 200,
            body: Rails.root.join("test/fixtures/90540140.json").read,
            headers: { "Content-Type" => "application/json" })

        items = [
          { width: 7.0, height: 2.0, length: 14.0, quantity: 1 },
          { width: 11.0, height: 2.0, length: 16.0, quantity: 2 }
        ]
        quotations = shop.quote(shipping_zip: "90540-140", products: items)

        quotations.size.must_equal(1)
        quotations[0].must_be_instance_of(Quotation)
        quotations[0].cotation_id.must_equal("")
        quotations[0].deadline.must_equal(0)
        quotations[0].deliver_company.must_equal("")
        quotations[0].delivery_type.must_equal("Normal")
        quotations[0].delivery_type_slug.must_equal("normal")
        quotations[0].name.must_equal("Canoas")
        quotations[0].notice.must_equal("")
        quotations[0].price.must_equal(0)
        quotations[0].slug.must_equal("canoas")
      end

      it "updates an existing rule for a new quotation" do
        stub_request(:get, "https://maps.googleapis.com/maps/api/geocode/json?address=90540-140&key&region=br").
          to_return(status: 200,
            body: Rails.root.join("test/fixtures/90540140.json").read,
            headers: { "Content-Type" => "application/json" })

        @shipping_method.map_rules.each { |rule| rule.update(price: 0) }

        assert_no_difference("@shipping_method.map_rules.count") do
          kml = Rails.root.join("test/fixtures/vnda.kml").read
          @shipping_method.build_or_update_map_rules_from(Nokogiri::XML(kml))
        end

        items = [
          { width: 7.0, height: 2.0, length: 14.0, quantity: 1 },
          { width: 11.0, height: 2.0, length: 16.0, quantity: 2 }
        ]
        quotations = shop.quote(shipping_zip: "90540-140", products: items)

        quotations.size.must_equal(1)
        quotations[0].must_be_instance_of(Quotation)
        quotations[0].cotation_id.must_equal("")
        quotations[0].deadline.must_equal(0)
        quotations[0].deliver_company.must_equal("")
        quotations[0].delivery_type.must_equal("Normal")
        quotations[0].delivery_type_slug.must_equal("normal")
        quotations[0].name.must_equal("Canoas")
        quotations[0].notice.must_equal("")
        quotations[0].price.must_equal(0)
        quotations[0].slug.must_equal("canoas")
      end
    end

    describe "for places" do
      it "generates a new quotation"
    end

    describe "for weight" do
      it "generates a new quotation"
    end
  end
end

# == Schema Information
#
# Table name: shops
#
#  id                    :integer          not null, primary key
#  name                  :string(255)      not null
#  token                 :string(32)       not null
#  axado_token           :string(32)
#  forward_to_axado      :boolean          default(FALSE), not null
#  correios_code         :string(255)
#  correios_password     :string(255)
#  forward_to_correios   :boolean          default(FALSE), not null
#  correios_services     :integer          default([]), not null, is an Array
#  normal_shipping_name  :string(255)
#  express_shipping_name :string(255)
#
