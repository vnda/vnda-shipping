require 'test_helper'

describe ShippingMethodsController do
  setup do
    @shop = shops(:one)
    @shipping_method = shipping_methods(:one)
  end

  let(:shop_params) { { name: "Loja Teste"} }
  let(:shop) { Shop.create shop_params }

  let(:shipping_method_params) { { name: "Metodo 1", slug: "metodo-1", shop_id: shop.id} }
  let(:shipping_method) { ShippingMethod.create shipping_method_params }

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
      post :create, shipping_method: { name: 'Metodo 2', slug: 'metodo-2', shop: @shop}, shop_id: @shop
    end
    assert_redirected_to edit_shop_shipping_method_path(@shop, ShippingMethod.last)
  end

  test "should get edit" do
    get :edit, shop_id: shop, id: shipping_method
    assert_response :success
  end

end
