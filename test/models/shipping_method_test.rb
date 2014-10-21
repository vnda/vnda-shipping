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
    it "set with_range" do
      shipping_method.weigth_range.must_equal (-BigDecimal::INFINITY...BigDecimal::INFINITY)
      shipping_method.min_weigth = 10
      shipping_method.max_weigth = 100

      shipping_method.valid?.must_equal true
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
