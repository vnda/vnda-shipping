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

  it "200 if quotation for marketplace" do
    shop = create_shop(
      forward_to_correios: true,
      correios_code: "correioscode",
      correios_password: "correiosp@ss"
    )

    normal = shop.methods.where(slug: "pac").first!
    express = shop.methods.where(slug: "sedex").first!

    shop.quotations.create!(
      cart_id: 1,
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
      name: express.name,
      deadline: 4,
      slug: express.slug,
      delivery_type: express.delivery_type.name,
      notice: express.notice,
      price: 20,
      skus: ["A2"]
    )

    get "/quotations/expressa", token: shop.token

    expect(response.status).to eq(200)

    quotation = JSON.load(body)

    expect(quotation["package"]).to eq(nil)
    expect(quotation["name"]).to eq("Expressa")
    expect(quotation["price"]).to eq(20.0)
    expect(quotation["deadline"]).to eq(4)
    expect(quotation["slug"]).to eq("sedex")
    expect(quotation["delivery_type"]).to eq("Expressa")
    expect(quotation["delivery_type_slug"]).to eq("expressa")
  end

  it "200 if quotation for seller" do
    shop = create_shop(
      forward_to_correios: true,
      correios_code: "correioscode",
      correios_password: "correiosp@ss"
    )

    normal = shop.methods.where(slug: "pac").first!
    express = shop.methods.where(slug: "sedex").first!

    shop.quotations.create!(
      cart_id: 1,
      package: "foo",
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
      package: "foo",
      name: express.name,
      deadline: 4,
      slug: express.slug,
      delivery_type: express.delivery_type.name,
      notice: express.notice,
      price: 20,
      skus: ["A2"]
    )

    get "/quotations/normal/foo", token: shop.token

    expect(response.status).to eq(200)

    quotation = JSON.load(body)

    expect(quotation["package"]).to eq("foo")
    expect(quotation["name"]).to eq("Normal")
    expect(quotation["price"]).to eq(8)
    expect(quotation["deadline"]).to eq(10)
    expect(quotation["slug"]).to eq("pac")
    expect(quotation["delivery_type"]).to eq("Normal")
    expect(quotation["delivery_type_slug"]).to eq("normal")
  end

  def create_shop(attributes = {})
    Shop.create!({ name: 'Loja', token: "a1b2c3", zip: "03320000" }.merge(attributes))
  end
end
