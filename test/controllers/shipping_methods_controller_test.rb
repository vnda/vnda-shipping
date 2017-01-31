require 'test_helper'

describe ShippingMethodsController do
  setup do
    @shop = shops(:one)
    @shipping_method = shipping_methods(:one)
  end

  let(:shop_params) { { name: "Loja Teste"} }
  let(:shop) { Shop.create shop_params }

  let(:shipping_method_params) { { name: "Metodo 1", slug: "metodo-1", shop_id: shop.id} }
  let(:shipping_method) { ShippingMethod.create!(shipping_method_params) }

  test "should get index" do
    get :index, shop_id: @shop
    assert_response :success
  end

  test "should get new" do
    get :new, shop_id: @shop
    assert_response :success
  end

  test "should create shipping_method" do
    assert_difference('ShippingMethod.count') do
      post :create, shipping_method: { name: 'Metodo 5', slug: 'metodo-5', description: "método cinco", shop: @shop, delivery_type_id: @shipping_method.delivery_type_id}, shop_id: @shop
    end
    assert_redirected_to edit_shop_shipping_method_path(@shop, ShippingMethod.order(:id).last)
  end
end
