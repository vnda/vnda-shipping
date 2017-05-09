require "rails_helper"

RSpec.describe PackageQuotations do
  it "calculates for multiple packages" do
    marketplace = create_shop(
      forward_to_correios: true,
      correios_code: "correioscode",
      correios_password: "correiosp@ss",
      zip: "03320000"
    )

    child_1 = create_shop(
      name: "Loja 1",
      forward_to_correios: true,
      correios_code: "loja1code",
      correios_password: "loja1p@ss",
      marketplace_id: marketplace.id,
      marketplace_tag: "child-1",
      zip: "03320000"
    )

    child_2 = create_shop(
      name: "Loja 2",
      forward_to_correios: true,
      correios_code: "loja2code",
      correios_password: "loja2p@ss",
      marketplace_id: marketplace.id,
      marketplace_tag: "child-2",
      zip: "03320000"
    )

    products = [
      { width: 7.0, height: 2.0, length: 14.0, quantity: 1, tags: ["camiseta", "child-1"] },
      { width: 2.0, height: 1.0, length: 6.0, quantity: 1, tags: ["meia"] },
      { width: 9.0, height: 5.0, length: 24.0, quantity: 1, tags: ["calca", "child-2"] }
    ]

    marketplace_quotations = [express_quotation(shop_id: marketplace.id, price: 9, deadline: 10, package_suffix: 1), normal_quotation(shop_id: marketplace.id, price: 6, deadline: 19, package_suffix: 1)]
    child_1_quotations = [express_quotation(shop_id: child_1.id, price: 10, deadline: 10, package_suffix: 2), normal_quotation(shop_id: child_1.id, price: 5, deadline: 20, package_suffix: 2)]
    child_2_quotations = [express_quotation(shop_id: child_2.id, price: 8, deadline: 11, package_suffix: 3), normal_quotation(shop_id: child_2.id, price: 7, deadline: 15, package_suffix: 3)]

    quotations_marketplace = double("quotations_marketplace", to_a: marketplace_quotations)
    quotations_child_1 = double("quotations_child_1", to_a: child_1_quotations)
    quotations_child_2 = double("quotations_child_2", to_a: child_2_quotations)

    expect(Quotations).to receive(:new).once.
      with(marketplace, { package: "A1B2C3-01", products: [products[1]], shipping_zip: "80035120" }, Rails.logger).
      and_return(quotations_marketplace)

    expect(Quotations).to receive(:new).once.
      with(child_1, { package: "A1B2C3-02", products: [products[0]], shipping_zip: "80035120" }, Rails.logger).
      and_return(quotations_child_1)

    expect(Quotations).to receive(:new).once.
      with(child_2, { package: "A1B2C3-03", products: [products[2]], shipping_zip: "80035120" }, Rails.logger).
      and_return(quotations_child_2)

    quotations = PackageQuotations.
      new(marketplace, { package_prefix: "A1B2C3", shipping_zip: "80035120", products: products }, Rails.logger).
      to_h

    expect(quotations.keys).to eq(["A1B2C3-1", "A1B2C3-2", "A1B2C3-3", :total_packages, :total_quotations])

    expect(quotations["A1B2C3-1"].size).to eq(2)

    expect(quotations["A1B2C3-1"][0].slug).to eq("expressa")
    expect(quotations["A1B2C3-1"][0].price).to eq(9)
    expect(quotations["A1B2C3-1"][0].deadline).to eq(10)

    expect(quotations["A1B2C3-2"].size).to eq(2)

    expect(quotations["A1B2C3-2"][0].slug).to eq("expressa")
    expect(quotations["A1B2C3-2"][0].price).to eq(10)
    expect(quotations["A1B2C3-2"][0].deadline).to eq(10)

    expect(quotations["A1B2C3-3"].size).to eq(2)

    expect(quotations["A1B2C3-3"][0].slug).to eq("expressa")
    expect(quotations["A1B2C3-3"][0].price).to eq(8)
    expect(quotations["A1B2C3-3"][0].deadline).to eq(11)
  end

  def create_shop(attributes = {})
    Shop.create!({ name: 'Loja', token: "a1b2c3" }.merge(attributes))
  end

  def express_quotation(attributes)
    Quotation.create!({
      cart_id: 1,
      package: "A1B2C3-#{attributes[:package_suffix]}",
      name: "Expressa",
      slug: "expressa",
      delivery_type: "Expressa",
      skus: ["A1"]
    }.merge(attributes.except(:package_suffix)))
  end

  def normal_quotation(attributes)
    Quotation.create!({
      cart_id: 1,
      package: "A1B2C3-#{attributes[:package_suffix]}",
      name: "Normal",
      slug: "normal",
      delivery_type: "Normal",
      skus: ["A2"]
    }.merge(attributes.except(:package_suffix)))
  end
end
