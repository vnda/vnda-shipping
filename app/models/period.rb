class Period < ActiveRecord::Base
  belongs_to :shop

  validates :name, :limit_time, presence: true

  DAYS = ['Domingo', 'Segunda']

end
