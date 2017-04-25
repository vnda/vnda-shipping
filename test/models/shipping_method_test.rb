require 'test_helper'

describe ShippingMethod do
  setup do
    @shop = shops(:one)
    @shipping_method = shipping_methods(:one)
  end

  let(:shipping_method_params) { { id: 1, name: "Metodo Teste", shop: @shop, delivery_type_id: @shipping_method.delivery_type_id, description: "Método Teste" } }
  let(:shipping_method) { ShippingMethod.new(shipping_method_params) }

  it "is valid with valid params" do
    shipping_method.must_be :valid?
  end

  it "is invalid without a name" do
    shipping_method_params.delete :name

    shipping_method.wont_be :valid?
    shipping_method.errors[:name].must_be :present?
  end

  describe "when validating" do
    it "set weigth_range" do
      shipping_method.weigth_range.must_equal(0..1000)
      shipping_method.min_weigth = 10
      shipping_method.max_weigth = 100

      shipping_method.must_be :valid?
      shipping_method.save!

      shipping_method.weigth_range.must_equal(10..100)
    end
  end

  describe "when saving" do
    it "generates a slug" do
      shipping_method.slug.must_be :nil?
      shipping_method.save!
      shipping_method.slug.wont_be :nil?
    end
  end

  describe "#build_or_update_map_rules_from" do
    it 'creates map rules from a .kml file' do
      map_rules = @shipping_method.build_or_update_map_rules_from(Nokogiri::XML(Rails.root.join("test/fixtures/regions.kml").read))

      map_rules.size.must_equal(9)
      map_rules[0].name.must_equal("itacorubi")
      map_rules[1].name.must_equal("academia")
      map_rules[2].name.must_equal("Santa Monica")
      map_rules[3].name.must_equal("Ponto 4")
      map_rules[4].name.must_equal("Ponto 5")
      map_rules[5].name.must_equal("Ponto 6")
      map_rules[6].name.must_equal("Ponto 7")
      map_rules[7].name.must_equal("parque")
      map_rules[8].name.must_equal("Ponto 9")
    end

    it 'updates map rules from .kml file' do
      @shipping_method.build_or_update_map_rules_from(Nokogiri::XML(Rails.root.join("test/fixtures/vnda-old.kml").read))

      @shipping_method.map_rules.size.must_equal(1)
      @shipping_method.map_rules[0].name.must_equal("Vnda")

      region = @shipping_method.map_rules[0].region

      @shipping_method.map_rules.each { |rule| rule.update_column(:price, 0) }
      @shipping_method.build_or_update_map_rules_from(Nokogiri::XML(Rails.root.join("test/fixtures/vnda.kml").read))

      @shipping_method.map_rules(true).size.must_equal(1)
      @shipping_method.map_rules[0].name.must_equal("Vnda")

      @shipping_method.map_rules[0].region.wont_equal(region)
    end
  end

  describe "#next_delivery_date" do
    setup do
      Timecop.freeze(2017, 4, 25, 9, 21, 55)
    end

    teardown do
      Timecop.return
    end

    it "return current date if days off is empty" do
      @shipping_method.next_delivery_date.day.must_equal(25)
    end

    it "return current date when all days is blocked" do
      @shipping_method.days_off = ["", "0", "1" "2", "3", "4", "5", "6"]
      @shipping_method.next_delivery_date.day.must_equal(25)
    end

    it "return next delivery date" do
      @shipping_method.days_off = ["2", "3", "4"]
      @shipping_method.next_delivery_date.day.must_equal(28)
    end
  end
end

# == Schema Information
#
# Table name: shipping_methods
#
#  id               :integer          not null, primary key
#  shop_id          :integer          not null
#  name             :string(255)      not null
#  description      :string(255)      default(""), not null
#  slug             :string(255)      not null
#  express          :boolean          default(FALSE), not null
#  enabled          :boolean          default(FALSE), not null
#  weigth_range     :numrange         default(BigDecimal(-Infinity)...BigDecimal(Infinity)), not null
#  delivery_type_id :integer
#
