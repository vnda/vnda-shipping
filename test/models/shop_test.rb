class ShopTest < ActiveSupport::TestCase

  def valid_params
    { name: "Loja 1" }
  end

  def test_valid
    shop = Shop.new valid_params

    assert shop.valid?, "Can't create with valid params: #{shop.errors.messages}"
  end

  def test_invalid_without_name
    params = valid_params.clone
    params.delete :name
    shop = Shop.new params

    refute shop.valid?, "Can't be valid without name"
    assert shop.errors[:name], "Missing error when without name"
  end

end
