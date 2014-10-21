# == Schema Information
#
# Table name: delivery_types
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  enabled    :boolean
#  created_at :datetime
#  updated_at :datetime
#  shop_id    :integer
#

require 'test_helper'

describe DeliveryType do
  setup do
    @shop = shops(:one)
    @delivery_type = delivery_types(:one)
  end

  let(:delivery_type_params) { { id: 1, name: "Tipo de envio Teste", shop: @shop} }
  let(:delivery_type) { DeliveryType.new delivery_type_params }

  it "is valid with valid params" do
    @delivery_type.must_be :valid?
  end

  it "is invalid without a name" do
    delivery_type_params.delete :name

    delivery_type.wont_be :valid?
    delivery_type.errors[:name].must_be :present?
  end

end
