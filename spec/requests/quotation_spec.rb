require 'rails_helper'

RSpec.describe "Quotation" do
  it "unauthorized if no token" do
    get "/quotations/foo/bar", token: nil
    expect(response.status).to eq(401)
  end

  it "404 if no quotation" do
    shop = create_shop

    expect do
      get "/quotations/foo/bar", token: shop.token
    end.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "200 if quotation" do
    shop = create_shop(
      forward_to_correios: true,
      correios_code: "correioscode",
      correios_password: "correiosp@ss"
    )

    normal, express = shop.methods[0..1]

    shop.quotations.create!(
      cart_id: 1,
      package: "A1B2C3-1",
      name: normal.name,
      deadline: 10,
      slug: normal.slug,
      delivery_type: normal.delivery_type.name,
      notice: normal.notice,
      price: 8,
      skus: ["A1"]
    )

    shop.quotations.create!(
      cart_id: 1,
      package: "A1B2C3-1",
      name: express.name,
      deadline: 4,
      slug: express.slug,
      delivery_type: express.delivery_type.name,
      notice: express.notice,
      price: 20,
      skus: ["A2"]
    )

    get "/quotations/A1B2C3-1/expressa", token: shop.token

    expect(response.status).to eq(200)

    quotation = JSON.load(body)

    expect(quotation["package"]).to eq("A1B2C3-1")
    expect(quotation["name"]).to eq("Expressa")
    expect(quotation["price"]).to eq(20.0)
    expect(quotation["deadline"]).to eq(4)
    expect(quotation["slug"]).to eq("sedex")
    expect(quotation["delivery_type"]).to eq("Expressa")
    expect(quotation["delivery_type_slug"]).to eq("expressa")
  end

  def create_shop(attributes = {})
    Shop.create!({ name: 'Loja', token: "a1b2c3", zip: "03320000" }.merge(attributes))
  end
end
