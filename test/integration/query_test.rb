require 'test_helper'

class QueryTest < ActionDispatch::IntegrationTest
  test "quotation from zip rules" do
    shop = Shop.create!(name: 'Body Store')
    method = shop.methods.create!(name: 'Motoboy')
    method.zip_rules.create!([
      { range: 1..5, price: 15.0, deadline: 2 },
      { range: 7..10, price: 20.0, deadline: 1 },
      { range: 11..15, price: 25.0, deadline: 3 }
    ])

    assert_equal [Quotation.new(name: 'Motoboy', price: 15.0, deadline: 2)], shop.quote_zip(5)
    assert_equal [], shop.quote_zip(6)
    assert_equal [Quotation.new(name: 'Motoboy', price: 25.0, deadline: 3)], shop.quote_zip(11)
  end

  test "validate ranges" do
    shop = Shop.create!(name: 'Body Store')
    method = shop.methods.create!(name: 'Motoboy')

    assert_raise ActiveRecord::RecordInvalid do
      method.zip_rules.create!([
        { range: 1..5, price: 5.0, deadline: 1 },
        { range: 5..10, price: 5.0, deadline: 1 }
      ])
    end
  end
end
