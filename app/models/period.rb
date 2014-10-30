# == Schema Information
#
# Table name: periods
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  limit_time :time
#  days_off   :text
#  created_at :datetime
#  updated_at :datetime
#  shop_id    :integer
#

class Period < ActiveRecord::Base
  belongs_to :shop
  has_and_belongs_to_many :zip_rules

  validates :name, :limit_time, presence: true
  serialize :days_off

  DAYS = ['Sábado', 'Domingo', 'Segunda-Feira', 'Terça-Feira',
               'Quarta-Feira', 'Quinta-Feira', 'Sexta-Feira']

  def next_day(day)
    week_day = day.strftime("%A")
    case week_day
    when 'Sunday'
      self.days_off.grep('Domingo').present? ? self.next_day(day + 1.day) : day
    when 'Monday'
      self.days_off.grep('Segunda-Feira').present? ? self.next_day(day + 1.day) : day
    when 'Tuesday'
      self.days_off.grep('Terça-Feira').present? ? self.next_day(day + 1.day) : day
    when 'Wednesday'
      self.days_off.grep('Quarta-Feira').present? ? self.next_day(day + 1.day) : day
    when 'Thursday'
      self.days_off.grep('Quinta-Feira').present? ? self.next_day(day + 1.day) : day
    when 'Friday'
      self.days_off.grep('Sexta-Feira').present? ? self.next_day(day + 1.day) : day
    when 'Saturday'
      self.days_off.grep('Sábado').present? ? self.next_day(day + 1.day) : day
    end
  end

end
