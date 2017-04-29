require "rails_helper"

RSpec.describe "Sellers" do
  it "returns 401 if token is invalid" do
    get "/shops/#{"a" * 32}/sellers.json"

    expect(response.status).to eq(401)
  end

  it "empty if shop has no sellers" do
    get "/shops/#{create_shop.token}/sellers.json"

    expect(response.status).to eq(200)

    sellers = JSON.load(body)
    expect(sellers).to eq([])
  end

  it "returns shop with its child-shops" do
    marketplace = create_shop
    marketplace.shops.create!(name: "Loja Filha", token: "c3b2a1", zip: "03320000")

    get "/shops/#{marketplace.token}/sellers.json"
    expect(response.status).to eq(200)

    sellers = JSON.load(body)
    expect(sellers.size).to eq(1)
    expect(sellers[0]["name"]).to eq("Loja Filha")
    expect(sellers[0]["token"].size).to eq(32)
  end

  def create_shop(attributes = {})
    Shop.create!({ name: 'Loja', token: "a1b2c3", zip: "03320000" }.reverse_merge(attributes))
  end
end
