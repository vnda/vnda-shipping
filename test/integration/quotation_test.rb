require 'test_helper'

class QuotationTest < ActionDispatch::IntegrationTest
  test "unauthorized if no token" do
    get "/quotations/foo/bar", token: nil
    assert_equal 401, status
  end

  test "404 if no quotation" do
    shop = create_shop

    assert_raise ActiveRecord::RecordNotFound do
      get "/quotations/foo/bar", token: shop.token
    end
  end

  test "200 if quotation" do
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
      price: 8
    )

    shop.quotations.create!(
      cart_id: 1,
      package: "A1B2C3-1",
      name: express.name,
      deadline: 4,
      slug: express.slug,
      delivery_type: express.delivery_type.name,
      notice: express.notice,
      price: 20
    )

    get "/quotations/A1B2C3-1/expressa", token: shop.token

    assert_equal 200, status

    quotation = JSON.load(body)

    assert_equal "A1B2C3-1", quotation["package"]
    assert_equal "Expressa", quotation["name"]
    assert_equal 20.0, quotation["price"]
    assert_equal 4, quotation["deadline"]
    assert_equal "sedex", quotation["slug"]
    assert_equal "Expressa", quotation["delivery_type"]
    assert_equal "expressa", quotation["delivery_type_slug"]
  end

  def create_shop(attributes = {})
    Shop.create!({ name: 'Loja', token: "a1b2c3" }.merge(attributes))
  end
end
