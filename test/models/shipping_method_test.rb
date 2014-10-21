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

describe ShippingMethod do
  setup do
    @shop = shops(:one)
    @shipping_method = shipping_methods(:one)
  end

  let(:shipping_method_params) { { id: 1, name: "Metodo Teste", shop: @shop} }
  let(:shipping_method) { ShippingMethod.new shipping_method_params }

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
      shipping_method.weigth_range.must_equal (-BigDecimal::INFINITY...BigDecimal::INFINITY)
      shipping_method.min_weigth = 10
      shipping_method.max_weigth = 100

      shipping_method.must_be :valid?
      shipping_method.save!

      shipping_method.weigth_range.must_equal (10..100)

    end
  end

  describe "when saving" do
      it "generates a slug" do
        shipping_method.slug.must_be :nil?
        shipping_method.save!
        shipping_method.slug.wont_be :nil?
      end
    end

end
