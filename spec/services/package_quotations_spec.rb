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

    products = {
      "" => [
        { width: 2.0, height: 1.0, length: 6.0, quantity: 1 },
      ],
      "child-1" => [
        { width: 7.0, height: 2.0, length: 14.0, quantity: 1 },
      ],
      "child-2" => [
        { width: 9.0, height: 5.0, length: 24.0, quantity: 1 }
      ]
    }

    marketplace_quotations = [express_quotation(shop_id: marketplace.id, price: 9, deadline: 10, package: nil), normal_quotation(shop_id: marketplace.id, price: 6, deadline: 19, package: nil)]
    child_1_quotations = [express_quotation(shop_id: child_1.id, price: 10, deadline: 10, package: "child-1"), normal_quotation(shop_id: child_1.id, price: 5, deadline: 20, package: "child-1")]
    child_2_quotations = [express_quotation(shop_id: child_2.id, price: 8, deadline: 11, package: "child-2"), normal_quotation(shop_id: child_2.id, price: 7, deadline: 15, package: "child-2")]

    quotations_marketplace = double("quotations_marketplace", to_a: marketplace_quotations)
    quotations_child_1 = double("quotations_child_1", to_a: child_1_quotations)
    quotations_child_2 = double("quotations_child_2", to_a: child_2_quotations)

    expect(Thread).to receive(:new).exactly(3).times.and_yield.and_return(double("thread").as_null_object)

    expect(Quotations).to receive(:new).once.
      with(marketplace, { products: products[""], package: "", shipping_zip: "80035120" }, Rails.logger).
      and_return(quotations_marketplace)

    expect(Quotations).to receive(:new).once.
      with(child_1, { products: products["child-1"], package: "child-1", shipping_zip: "80035120" }, Rails.logger).
      and_return(quotations_child_1)

    expect(Quotations).to receive(:new).once.
      with(child_2, { products: products["child-2"], package: "child-2", shipping_zip: "80035120" }, Rails.logger).
      and_return(quotations_child_2)

    quotations = described_class.
      new(marketplace, { shipping_zip: "80035120", products: products }, Rails.logger).
      to_h

    expect(quotations.keys).to eq(["", "child-1", "child-2"])

    expect(quotations[""].size).to eq(2)

    expect(quotations[""][0].slug).to eq("expressa")
    expect(quotations[""][0].price).to eq(9)
    expect(quotations[""][0].deadline).to eq(10)

    expect(quotations["child-1"].size).to eq(2)

    expect(quotations["child-1"][0].slug).to eq("expressa")
    expect(quotations["child-1"][0].price).to eq(10)
    expect(quotations["child-1"][0].deadline).to eq(10)

    expect(quotations["child-2"].size).to eq(2)

    expect(quotations["child-2"][0].slug).to eq("expressa")
    expect(quotations["child-2"][0].price).to eq(8)
    expect(quotations["child-2"][0].deadline).to eq(11)
  end

  def create_shop(attributes = {})
    Shop.create!({ name: 'Loja', token: "a1b2c3" }.merge(attributes))
  end

  def express_quotation(attributes)
    Quotation.create!({
      cart_id: 1,
      name: "Expressa",
      slug: "expressa",
      delivery_type: "Expressa",
      skus: ["A1"]
    }.merge(attributes.except(:package_suffix)))
  end

  def normal_quotation(attributes)
    Quotation.create!({
      cart_id: 1,
      name: "Normal",
      slug: "normal",
      delivery_type: "Normal",
      skus: ["A2"]
    }.merge(attributes.except(:package_suffix)))
  end
end
