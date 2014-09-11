class ZipRule < ActiveRecord::Base
  belongs_to :shipping_method

  scope :for_zip, -> zip { where('zip_rules.range @> ?', zip) }

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
