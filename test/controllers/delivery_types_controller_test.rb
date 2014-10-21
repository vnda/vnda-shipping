# describe ShopsController do
#   setup do
#     @shop = shops(:one)
#   end

#   test "should get index" do
#     get :index
#     assert_response :success
#   end

#   test "should get new" do
#     get :new
#     assert_response :success
#   end

#   test "should create shop" do
#     assert_difference('Shop.count') do
#       post :create, shop: { name: 'Loja 2'}
#     end

#     assert_redirected_to shop_shipping_methods_path(Shop.last)
#   end

#   test "should get edit" do
#     get :edit, id: @shop
#     assert_response :success
#   end

#   test "should update shop" do
#     patch :update, id: @shop, shop: { name: 'Loja 3' }
#     assert_redirected_to shops_path
#   end

#   test "should destroy shop" do
#     assert_difference('Shop.count', -1) do
#       delete :destroy, id: @shop
#     end

#     assert_redirected_to shops_path
#   end
# end
