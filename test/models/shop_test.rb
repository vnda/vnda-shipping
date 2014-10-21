describe Shop do

  let(:shop_params) { { id: 1, name: "Loja Teste"} }
  let(:shop) { Shop.new shop_params }

  it "is valid with valid params" do
    shop.must_be :valid?
  end

  it "is invalid without a name" do
    shop_params.delete :name

    shop.wont_be :valid?
    shop.errors[:name].must_be :present?
  end

  it "is invalid if axado is checked and axado_token is empty" do
    shop_params.merge!( {forward_to_axado: true})

    shop.wont_be :valid?
    shop.errors[:axado_token].must_be :present?
  end

  it "is valid if forward_to_axado is checked and axado_token is present" do
    shop_params.merge!( {forward_to_axado: true, axado_token: "12345678"})

    shop.must_be :valid?
  end

  it "is invalid if forward_to_correios is checked and correios_code or correios_password is empty" do
    shop_params.merge!( {forward_to_correios: true})

    shop.wont_be :valid?
    shop.errors[:correios_password].must_be :present?
    shop.errors[:correios_code].must_be :present?
  end

  it "is valid if correios is checked and correios_token is present" do
    shop_params.merge!( {forward_to_correios: true, correios_code: "12345678", correios_password: "abcdef"})

    shop.must_be :valid?
  end

 end
