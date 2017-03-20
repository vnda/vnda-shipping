require "test_helper"

class PackageQuotationsTest < ActiveSupport::TestCase
  test "calculates for multiple packages" do
    marketplace = create_shop(
      forward_to_correios: true,
      correios_code: "correioscode",
      correios_password: "correiosp@ss"
    )

    child_1 = create_shop(
      name: "Loja 1",
      forward_to_correios: true,
      correios_code: "loja1code",
      correios_password: "loja1p@ss",
      marketplace_id: marketplace.id,
      marketplace_tag: "child-1"
    )

    child_2 = create_shop(
      name: "Loja 2",
      forward_to_correios: true,
      correios_code: "loja2code",
      correios_password: "loja2p@ss",
      marketplace_id: marketplace.id,
      marketplace_tag: "child-2"
    )

    products = [
      { width: 7.0, height: 2.0, length: 14.0, quantity: 1, tags: ["camiseta", "child-1"] },
      { width: 2.0, height: 1.0, length: 6.0, quantity: 1, tags: ["meia"] },
      { width: 9.0, height: 5.0, length: 24.0, quantity: 1, tags: ["calca", "child-2"] }
    ]

    marketplace_quotations = [express_quotation(shop_id: marketplace.id, price: 9, deadline: 10, package_suffix: 1), normal_quotation(shop_id: marketplace.id, price: 6, deadline: 19, package_suffix: 1)]
    child_1_quotations = [express_quotation(shop_id: child_1.id, price: 10, deadline: 10, package_suffix: 2), normal_quotation(shop_id: child_1.id, price: 5, deadline: 20, package_suffix: 2)]
    child_2_quotations = [express_quotation(shop_id: child_2.id, price: 8, deadline: 11, package_suffix: 3), normal_quotation(shop_id: child_2.id, price: 7, deadline: 15, package_suffix: 3)]

    quotations_mock = MiniTest::Mock.new
    quotations_mock.expect(:to_a, marketplace_quotations)
    quotations_mock.expect(:to_a, child_1_quotations)
    quotations_mock.expect(:to_a, child_2_quotations)

    quotations_class_mock = MiniTest::Mock.new
    quotations_class_mock.expect(:new, quotations_mock, [marketplace, { package: "A1B2C3-01", origin_zip: "03320000", products: [products[1]], shipping_zip: "80035120" }, Rails.logger])
    quotations_class_mock.expect(:new, quotations_mock, [child_1, { package: "A1B2C3-02", origin_zip: "03320000", products: [products[0]], shipping_zip: "80035120" }, Rails.logger])
    quotations_class_mock.expect(:new, quotations_mock, [child_2, { package: "A1B2C3-03", origin_zip: "03320000", products: [products[2]], shipping_zip: "80035120" }, Rails.logger])

    quotations = PackageQuotations.
      new(marketplace, { package_prefix: "A1B2C3", origin_zip: "03320000", shipping_zip: "80035120", products: products }, Rails.logger).
      to_h(quotations_class_mock)

    assert_equal ["A1B2C3-1", "A1B2C3-2", "A1B2C3-3", :total_packages, :total_quotations], quotations.keys

    assert_equal 2, quotations["A1B2C3-1"].size

    assert_equal "expressa", quotations["A1B2C3-1"][0].slug
    assert_equal 9, quotations["A1B2C3-1"][0].price
    assert_equal 10, quotations["A1B2C3-1"][0].deadline

    assert_equal 2, quotations["A1B2C3-2"].size

    assert_equal "expressa", quotations["A1B2C3-2"][0].slug
    assert_equal 10, quotations["A1B2C3-2"][0].price
    assert_equal 10, quotations["A1B2C3-2"][0].deadline

    assert_equal 2, quotations["A1B2C3-3"].size

    assert_equal "expressa", quotations["A1B2C3-3"][0].slug
    assert_equal 8, quotations["A1B2C3-3"][0].price
    assert_equal 11, quotations["A1B2C3-3"][0].deadline
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
