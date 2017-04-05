require 'test_helper'

describe Shop do
  let(:shop_params) { { id: 1, name: "Loja Teste", zip: "03320000" } }
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
