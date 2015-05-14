# == Schema Information
#
# Table name: zip_rules
#
#  id                 :integer          not null, primary key
#  shipping_method_id :integer          not null
#  range              :int4range        not null
#  price              :decimal(10, 2)
#  deadline           :integer          not null
#

class ZipRule < ActiveRecord::Base
  belongs_to :shipping_method
  has_one :shop, through: :shipping_method
  has_and_belongs_to_many :periods

  scope :for_zip, -> zip { where('zip_rules.range @> ?', zip) }
  scope :order_by_limit, -> { joins(:periods).order("periods.limit_time") }

  attr_writer :min, :max
  def min; @min ||= range.try(:min) end
  def max; @max ||= range.try(:max) end

  before_validation do
    self.range = Range.new(*[min, max].map { |v| v.to_s.gsub(/\D/, '').to_i })
  end

  validates :price, :deadline, presence: true

  def price=(v)
    super(v.is_a?(String) ? v.gsub(?., '').gsub(?,, ?.) : v)
  end
end
