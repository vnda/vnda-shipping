# class ShopTest < ActiveSupport::TestCase
describe Shop do

  let(:shop_params) { { name: "Loja 1" } }
  let(:shop) { Shop.new shop_params }

  it "is valid with valid params" do
    shop.must_be :valid? # Must create with valid params

  end

  it "is invalid without a name" do
    shop_params.delete :name

    shop.wont_be :valid? #Must not be valid without email
    shop.errors[:name].must_be :present? # Must have error for missing email

  end

end
