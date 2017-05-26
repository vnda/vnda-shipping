require "rails_helper"

describe PickingTime do
  let(:monday) { PickingTime.create!(enabled: true, weekday: "monday", hour: "14:00", shop_id: 1) }
  let(:tuesday) { PickingTime.create!(enabled: true, weekday: "tuesday", hour: "10:00", shop_id: 1) }
  let(:wednesday) { PickingTime.create!(enabled: true, weekday: "wednesday", hour: "10:00", shop_id: 1) }
  let(:thursday) { PickingTime.create!(enabled: true, weekday: "thursday", hour: "10:00", shop_id: 1) }
  let(:friday) { PickingTime.create!(enabled: true, weekday: "friday", hour: "10:00", shop_id: 1) }
  let(:saturday) {  PickingTime.create!(enabled: true, weekday: "saturday", hour: "18:00", shop_id: 1) }
  let(:sunday) { PickingTime.create!(enabled: true, weekday: "sunday", hour: "18:00", shop_id: 1) }

  describe "#time" do
    it "returns the related time" do
      Timecop.travel(2013, 8, 16, 1, 45, 0) do
        expect(monday.time).to eq(Time.new(2013, 8, 19, 14, 0, 0))
        expect(tuesday.time).to eq(Time.new(2013, 8, 20, 10, 0, 0))
        expect(wednesday.time).to eq(Time.new(2013, 8, 21, 10, 0, 0))
        expect(thursday.time).to eq(Time.new(2013, 8, 22, 10, 0, 0))
        expect(friday.time).to eq(Time.new(2013, 8, 16, 10, 0, 0))
        expect(saturday.time).to eq(Time.new(2013, 8, 17, 18, 0, 0))
        expect(sunday.time).to eq(Time.new(2013, 8, 18, 18, 0, 0))
      end
    end
  end

  describe "#next_time" do
    it "returns monday at monday before picking time" do
      Timecop.travel(2013, 8, 12, 10, 20, 0) do
        setup_picking_schedule

        expect(described_class.next_time(1).time).to eq(Time.new(2013, 8, 12, 14, 0, 0))
      end
    end

    it "returns tuesday at monday after picking time" do
      Timecop.travel(2013, 8, 12, 14, 20, 0) do
        setup_picking_schedule

        expect(described_class.next_time(1).time).to eq(Time.new(2013, 8, 13, 10, 0, 0))
      end
    end

    it "returns friday at friday before picking time" do
      Timecop.travel(2013, 8, 16, 1, 45, 0) do
        setup_picking_schedule

        expect(described_class.next_time(1).time).to eq(Time.new(2013, 8, 16, 10, 0, 0))
      end
    end
  end

  describe "#+" do
    context "before picking time" do
      around do |example|
        Timecop.travel(2013, 8, 12, 1, 45, 0) do
          example.run
        end
      end

      before { setup_picking_schedule }

      context "on business days" do
        it "returns 0 for 0" do
          expect(monday + 0).to eq(0)
        end

        it "returns 1 for 1" do
          expect(monday + 1).to eq(1)
        end

        it "returns 2 for 2" do
          expect(monday + 2).to eq(2)
        end

        it "returns 3 for 3" do
          expect(monday + 3).to eq(3)
        end

        it "returns 4 for 4" do
          expect(monday + 4).to eq(4)
        end
      end

      context "on weekends" do
        it "returns 5 for 5" do
          expect(monday + 5).to eq(5)
        end

        it "returns 6 for 6" do
          expect(monday + 6).to eq(6)
        end
      end
    end

    context "after picking time" do
      around do |example|
        Timecop.travel(2013, 8, 12, 14, 45, 0) do
          example.run
        end
      end

      before { setup_picking_schedule }

      context "on business days" do
        it "returns 1 for 0" do
          expect(monday + 0).to eq(1)
        end

        it "returns 2 for 1" do
          expect(monday + 1).to eq(2)
        end

        it "returns 3 for 2" do
          expect(monday + 2).to eq(3)
        end

        it "returns 4 for 3" do
          expect(monday + 3).to eq(4)
        end
      end

      context "on weekends" do
        it "returns 5 for 4" do
          expect(monday + 4).to eq(5)
        end

        it "returns 6 for 5" do
          expect(monday + 5).to eq(6)
        end

        it "returns 7 for 6" do
          expect(monday + 6).to eq(7)
        end
      end
    end
  end

  def setup_picking_schedule
    monday
    tuesday
    wednesday
    thursday
    friday
    saturday
    sunday
  end
end
