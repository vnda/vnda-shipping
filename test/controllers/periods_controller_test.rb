require 'test_helper'

describe PeriodsController do
  setup do
    @shop = shops(:one)
    @period = periods(:one)
  end

  test "should get index" do
    get :index, shop_id: @shop.id
    assert_response :success
    assert_not_nil assigns(:periods)
  end

  test "should get new" do
    get :new, shop_id: @shop.id
    assert_response :success
  end

  test "should create period" do
    assert_difference('Period.count') do
      post :create, period: { shop: @shop, days_off: @period.days_off, limit_time: @period.limit_time, name: @period.name }, shop_id: @shop
    end

    assert_redirected_to edit_shop_period_path(@shop, assigns(:period))
  end

  test "should show period" do
    get :show, shop_id: @shop.id, id: @period
    assert_response :success
  end

  test "should get edit" do
    get :edit, shop_id: @shop.id, id: @period
    assert_response :success
  end

  test "should update period" do
    patch :update, id: @period, period: { days_off: @period.days_off, limit_time: @period.limit_time, name: @period.name }, shop_id: @shop.id
    assert_redirected_to edit_shop_period_path(@shop, assigns(:period))
  end

  test "should destroy period" do
    assert_difference('Period.count', -1) do
      delete :destroy, shop_id: @shop.id, id: @period
    end

    assert_redirected_to shop_periods_path(@shop)
  end
end
