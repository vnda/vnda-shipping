require "test_helper"

class ShowShopTest < ActionDispatch::IntegrationTest
  test "returns 404 if no shop" do
    assert_raises(ActiveRecord::RecordNotFound) do
      get "/shops/999.json"
    end
  end

  test "returns shop if found" do
    get "/shops/#{create_shop.token}.json"
    assert_equal 200, status

    shop = JSON.load(body)
    assert shop["id"] > 0
    assert_equal "Loja", shop["name"]
    assert_equal [], shop["shops"]
  end

  test "returns shop with its child-shops" do
    marketplace = create_shop
    marketplace.shops.create!(name: "Loja Filha", token: "c3b2a1")

    get "/shops/#{marketplace.token}.json"
    assert_equal 200, status

    shop = JSON.load(body)
    assert shop["id"] > 0
    assert_equal "Loja", shop["name"]
    assert_equal 1, shop["shops"].size
    assert_equal "Loja Filha", shop["shops"][0]["name"]
    assert_equal 32, shop["shops"][0]["token"].size
  end

  def create_shop(attributes = {})
    Shop.create!({ name: 'Loja', token: "a1b2c3" }.reverse_merge(attributes))
  end
end
