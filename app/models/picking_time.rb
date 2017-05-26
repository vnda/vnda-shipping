require "nickel"

class PickingTime < ActiveRecord::Base
  WEEKDAYS = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
  HOURS = [
    "08:00", "08:30", "09:00", "09:30", "10:00", "10:30", "11:00", "11:30",
    "12:00", "12:30", "13:00", "13:30", "14:00", "14:30", "15:00", "15:30",
    "16:00", "16:30", "17:00", "17:30", "18:00", "18:30"
  ]

  validates_uniqueness_of :weekday, scope: :shop_id
  validates_inclusion_of :weekday, :in => WEEKDAYS, :allow_blank => true

  def time
    occurrence = Nickel.parse("#{weekday} at #{hour}").occurrences.first
    Time.parse("#{occurrence.start_date.date} #{occurrence.start_time.time}")
  end

  def +(number)
    delivery_date = time
    delivery_date += 1.day unless Time.now < time
    delivery_date += number.day
    (delivery_date.end_of_day - Time.now).round / 60 / 60 / 24
  end

  def self.next_time(shop_id, now = nil)
    now ||= Time.now
    weekday = now.strftime("%A").downcase
    picking = where(shop_id: shop_id, enabled: true, weekday: weekday).first

    if picking
      hour, minute = picking.hour.split(":").map(&:to_i)
      return picking if Time.now < now.change(hour: hour, minute: minute)
    end

    next_time(shop_id, now + 1.day)
  end
end
