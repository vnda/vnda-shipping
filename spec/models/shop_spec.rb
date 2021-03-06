require "rails_helper"

describe Shop do
  let(:shop_params) { { id: 1, name: "Loja Teste", zip: "03320000" } }
  subject { Shop.new(shop_params) }

  it "is valid with valid params" do
    expect(subject).to be_valid
  end

  it "is invalid without a name" do
    shop_params.delete(:name)

    expect(subject).to_not be_valid
    expect(subject.errors[:name]).to eq(["não pode ficar em branco"])
  end

  it "is invalid if axado is checked and axado_token is empty" do
    shop_params.merge!( {forward_to_axado: true})

    expect(subject).to_not be_valid
    expect(subject.errors[:axado_token]).to eq(["não pode ficar em branco"])
  end

  it "is valid if forward_to_axado is checked and axado_token is present" do
    shop_params.merge!( {forward_to_axado: true, axado_token: "12345678"})

    expect(subject).to be_valid
  end

  it "is invalid if forward_to_correios is checked and correios_code or correios_password is empty" do
    shop_params.merge!( {forward_to_correios: true})

    expect(subject).to_not be_valid
    expect(subject.errors[:correios_password]).to eq(["não pode ficar em branco"])
    expect(subject.errors[:correios_code]).to eq(["não pode ficar em branco"])
  end

  it "is valid if correios is checked and correios_token is present" do
    shop_params.merge!( {forward_to_correios: true, correios_code: "12345678", correios_password: "abcdef"})

    expect(subject).to be_valid
  end

  it "creates default delivery types" do
    expect do
      subject.save!
    end.to change { subject.delivery_types.count }.from(0).to(2)
  end

  it "does not create correios shipping methods" do
    subject.forward_to_correios = false

    expect do
      subject.save!
    end.to_not change { subject.methods.count }.from(0)
  end

  it "creates correios shipping methods" do
    subject.forward_to_correios = true
    subject.correios_code = "a"
    subject.correios_password = "b"

    expect do
      subject.save!
    end.to change { subject.methods.count }.from(0).to(2)
  end

  describe "before creating" do
    it "generates a token" do
      expect do
        subject.save!
      end.to change { subject.token }.from(nil).to(/\w{32}/)
    end
  end

  describe "#volume_for" do
    it "returns zero if no items" do
      expect(subject.volume_for([])).to eq(0)
    end

    it "returns volume for all given items" do
      items = [
        { width: 7.0, height: 2.0, length: 14.0, quantity: 1 },
        { width: 11.0, height: 2.0, length: 16.0, quantity: 2 }
      ]

      expect(subject.volume_for(items)).to eq(900)
    end
  end

  describe "#shipping_methods_correios" do
    it "returns an empty array if correios is not enabled" do
      subject.save!

      expect(subject.shipping_methods_correios).to eq([])
    end

    it "returns shipping methods for correios when it's enabled" do
      subject.forward_to_correios = true
      subject.correios_code = "code"
      subject.correios_password = "pass"
      subject.save!

      expect(subject.shipping_methods_correios.size).to eq(2)

      normal = subject.shipping_methods_correios[0]
      expect(normal.name).to eq("Normal")
      expect(normal.delivery_type.name).to eq("Normal")

      express = subject.shipping_methods_correios[1]
      expect(express.name).to eq("Expressa")
      expect(express.delivery_type.name).to eq("Expressa")
    end
  end

  describe "#enabled_correios_service" do
    it "returns an empty array if no service is enabled for correios" do
      expect(subject.enabled_correios_service).to eq([])
    end

    it "returns an array of service codes enabled for correios" do
      subject.forward_to_correios = true
      subject.correios_code = "code"
      subject.correios_password = "pass"
      subject.save!

      expect(subject.enabled_correios_service).to eq(["04669", "04162"])
    end
  end
end

# == Schema Information
#
# Table name: shops
#
#  id                    :integer          not null, primary key
#  name                  :string(255)      not null
#  token                 :string(32)       not null
#  axado_token           :string(32)
#  forward_to_axado      :boolean          default(FALSE), not null
#  correios_code         :string(255)
#  correios_password     :string(255)
#  forward_to_correios   :boolean          default(FALSE), not null
#  correios_services     :integer          default([]), not null, is an Array
#  normal_shipping_name  :string(255)
#  express_shipping_name :string(255)
#
