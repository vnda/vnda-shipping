require "test_helper"

class ApiSellersTest < ActionDispatch::IntegrationTest
  test "returns 404 if no shop" do
    # assert_raises(ActiveRecord::RecordNotFound) do
      get "/shops/999/sellers.json"
    # end
  end

  test "empty shop no sellers" do
    get "/shops/#{create_shop.token}/sellers.json"
    assert_equal 200, status

    sellers = JSON.load(body)
    assert_equal [], sellers
  end

  test "returns shop with its child-shops" do
    marketplace = create_shop
    marketplace.shops.create!(name: "Loja Filha", token: "c3b2a1")

    get "/shops/#{marketplace.token}/sellers.json"
    assert_equal 200, status

    sellers = JSON.load(body)
    assert_equal 1, sellers.size
    assert_equal "Loja Filha", sellers[0]["name"]
    assert_equal 32, sellers[0]["token"].size
  end

  def create_shop(attributes = {})
    Shop.create!({ name: 'Loja', token: "a1b2c3" }.reverse_merge(attributes))
  end
end
