# == Schema Information
#
# Table name: periods
#
#  id             :integer          not null, primary key
#  name           :string(255)
#  limit_time     :time
#  days_off       :text
#  created_at     :datetime
#  updated_at     :datetime
#  shop_id        :integer
#  exception_date :text
#

class Period < ActiveRecord::Base
  belongs_to :shop
  has_and_belongs_to_many :zip_rules

  validates :name, :limit_time, presence: true
  serialize :days_off
  serialize :exception_date
  serialize :closed_date

  DAYS = ['Sábado', 'Domingo', 'Segunda-Feira', 'Terça-Feira',
               'Quarta-Feira', 'Quinta-Feira', 'Sexta-Feira']

  scope :valid_on, -> (time) { where("limit_time > ?", time) }

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

  def available_on?(date)
    status = case date.strftime("%A")
    when 'Sunday'
      self.days_off.grep('Domingo').present? ? false : true
    when 'Monday'
      self.days_off.grep('Segunda-Feira').present? ? false : true
    when 'Tuesday'
      self.days_off.grep('Terça-Feira').present? ? false : true
    when 'Wednesday'
      self.days_off.grep('Quarta-Feira').present? ? false : true
    when 'Thursday'
      self.days_off.grep('Quinta-Feira').present? ? false : true
    when 'Friday'
      self.days_off.grep('Sexta-Feira').present? ? false : true
    when 'Saturday'
      self.days_off.grep('Sábado').present? ? false : true
    end

    (status && !closed_date.to_s.include?( date.strftime("%d/%m/%Y") )) || exception_date.to_s.include?( date.strftime("%d/%m/%Y") )
  end

end
