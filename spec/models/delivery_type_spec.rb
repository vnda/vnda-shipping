require "rails_helper"

describe DeliveryType do
  it "validates presence of name" do
    expect(subject).to_not be_valid
    expect(subject.errors[:name]).to eq(["não pode ficar em branco"])
    expect(subject.errors[:shop_id]).to eq(["não pode ficar em branco"])
  end

  it "validates uniqueness of name" do
    subject.shop_id = 1
    subject.name = "Expressa"
    subject.save!

    delivery_type = described_class.new(name: "Expressa", shop_id: subject.shop_id)

    expect(delivery_type).to_not be_valid
    expect(delivery_type.errors[:name]).to eq(["já está em uso"])
  end

  it "validates with valid attributes" do
    subject.shop_id = 1
    subject.name = "Expressa"

    expect(subject).to be_valid
  end
end
