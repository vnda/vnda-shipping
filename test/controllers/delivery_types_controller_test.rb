require 'test_helper'

describe DeliveryTypesController do
  setup do
    @shop = shops(:one)
    @delivery_type = delivery_types(:one)
  end

  let(:shop_params) { { name: "Loja Teste"} }
  let(:shop) { Shop.create shop_params }

  let(:delivery_type_params) { { name: "Tipo de envio 1", shop_id: shop.id, enabled: false} }
  let(:delivery_type) { DeliveryType.create delivery_type_params }

  test "should get index" do
    get :index, shop_id: @shop
    assert_response :success
  end

  test "should get new" do
    get :new, shop_id: @shop
    assert_response :success
  end

  test "should create delivery_type" do
    assert_difference('DeliveryType.count') do
      post :create, delivery_type: { name: 'Tipo de envio 2', shop: @shop}, shop_id: @shop
    end
    assert_redirected_to shop_delivery_types_path(@shop)
  end

  test "should get edit" do
    get :edit, shop_id: shop, id: delivery_type
    assert_response :success
  end
end
