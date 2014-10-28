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

  validates :name, :limit_time, presence: true
  serialize :days_off

  DAYS = ['Sábado', 'Domingo', 'Segunda-Feira', 'Terça-Feira',
               'Quarta-Feira', 'Quinta-Feira', 'Sexta-Feira']

end
