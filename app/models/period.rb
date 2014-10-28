class Period < ActiveRecord::Base
  belongs_to :shop

  validates :name, :limit_time, presence: true

  DAYS = ['Sábado', 'Domingo', 'Segunda-Feira', 'Terça-Feira',
               'Quarta-Feira', 'Quinta-Feira', 'Sexta-Feira']

end
