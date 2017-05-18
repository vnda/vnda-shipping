require 'rails_helper'

RSpec.describe ShippingMethod do
  let(:shop) { Shop.create!(name: "loja", zip: "03320000") }
  subject { described_class.new(id: 1, name: "Metodo Teste", shop_id: shop.id, delivery_type_id: 1, description: "Método Teste") }

  it "returns valid if all parameters are valid" do
    expect(subject).to be_valid
  end

  it "returns invalid if name is empty" do
    subject.name = nil

    expect(subject).to_not be_valid
    expect(subject.errors[:name]).to eq(["não pode ficar em branco"])
  end

  it "returns invalid if min weight is less than max" do
    expect(subject.weigth_range).to eq(0..1000)

    subject.min_weigth = 100
    subject.max_weigth = 99

    expect(subject).to_not be_valid
    expect(subject.errors[:min_weigth]).to eq(["deve ser menor ou igual a 99.0"])
    expect(subject.errors[:max_weigth]).to eq(["deve ser maior ou igual a 100.0"])
  end

  it "returns invalid if max weight is greater than max allowed" do
    expect(subject.weigth_range).to eq(0..1000)

    subject.max_weigth = 1001

    expect(subject).to_not be_valid
    expect(subject.errors[:min_weigth]).to eq([])
    expect(subject.errors[:max_weigth]).to eq(["deve ser menor ou igual a 1000"])
  end

  describe "#set_weight" do
    it "sets min_weigth to the minimum allowed if empty" do
      subject.min_weigth = nil
      subject.max_weigth = nil

      subject.save!

      expect(subject.min_weigth).to eq(0)
      expect(subject.max_weigth).to eq(1000)
      expect(subject.weigth_range).to eq(0..1000)
    end

    it "does not change min/max weights if it's within allowed" do
      expect(subject.weigth_range).to eq(0..1000)

      subject.min_weigth = 10
      subject.max_weigth = 100

      subject.save!

      expect(subject.weigth_range).to eq(10..100)
    end
  end

  describe "#generate_slug" do
    it "generates a slug from description" do
      expect do
        subject.save!
      end.to change { subject.slug }.from(nil).to("metodo-teste")
    end

    it "generates a slug from the first part of description when it contains 'CSV'" do
      subject.description = "Transportadora CSV 0.0 até 0.6"

      expect do
        subject.save!
      end.to change { subject.slug }.from(nil).to("transportadora")
    end

    it "returns invalid if generated slug is empty" do
      subject.description = "CSV 0.0 até 0.6"

      expect(subject).to_not be_valid
      expect(subject.errors[:slug]).to eq(["não pode ficar em branco"])
    end
  end

  describe "#build_or_update_map_rules_from" do
    before { subject.save! }

    it "creates map rules from a .kml file" do
      map_rules = subject.build_or_update_map_rules_from(Nokogiri::XML(Rails.root.join("spec/fixtures/regions.kml").read))

      expect(map_rules.size).to eq(9)
      expect(map_rules[0].name).to eq("itacorubi")
      expect(map_rules[1].name).to eq("academia")
      expect(map_rules[2].name).to eq("Santa Monica")
      expect(map_rules[3].name).to eq("Ponto 4")
      expect(map_rules[4].name).to eq("Ponto 5")
      expect(map_rules[5].name).to eq("Ponto 6")
      expect(map_rules[6].name).to eq("Ponto 7")
      expect(map_rules[7].name).to eq("parque")
      expect(map_rules[8].name).to eq("Ponto 9")
    end

    it "updates map rules from .kml file" do
      subject.build_or_update_map_rules_from(Nokogiri::XML(Rails.root.join("spec/fixtures/vnda-old.kml").read))

      expect(subject.map_rules.size).to eq(1)
      expect(subject.map_rules[0].name).to eq("Vnda")

      region = subject.map_rules[0].region

      subject.map_rules.each { |rule| rule.update_column(:price, 0) }
      subject.build_or_update_map_rules_from(Nokogiri::XML(Rails.root.join("spec/fixtures/vnda.kml").read))

      expect(subject.map_rules(true).size).to eq(1)
      expect(subject.map_rules[0].name).to eq("Vnda")
      expect(subject.map_rules[0].region).to_not eq(region)
    end
  end

  describe "#next_delivery_date" do
    before { Timecop.freeze(2017, 4, 25, 9, 21, 55) }
    after { Timecop.return }

    it "returns current date if days off is empty" do
      expect(subject.next_delivery_date.day).to eq(25)
    end

    it "returns current date when all days is blocked" do
      subject.days_off = ["", "0", "1" "2", "3", "4", "5", "6"]
      expect(subject.next_delivery_date.day).to eq(25)
    end

    it "returns next delivery date" do
      subject.days_off = ["2", "3", "4"]
      expect(subject.next_delivery_date.day).to eq(28)
    end
  end
end

# == Schema Information
#
# Table name: shipping_methods
#
#  id               :integer          not null, primary key
#  shop_id          :integer          not null
#  name             :string(255)      not null
#  description      :string(255)      default(""), not null
#  slug             :string(255)      not null
#  express          :boolean          default(FALSE), not null
#  enabled          :boolean          default(FALSE), not null
#  weigth_range     :numrange         default(BigDecimal(-Infinity)...BigDecimal(Infinity)), not null
#  delivery_type_id :integer
#
