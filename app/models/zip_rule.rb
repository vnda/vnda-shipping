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
  validate :validate_no_overlap

  def price=(v)
    super(v.is_a?(String) ? v.gsub(?., '').gsub(?,, ?.) : v)
  end

  private

  def validate_no_overlap
    return if shipping_method.blank? || range.blank?
    overlap = shipping_method.zip_rules
      .where.not(id: id)
      .where("range && '[?,?]'::int4range", range.min, range.max)
    errors.add(:min, :overlaps) if overlap.exists?
  end
end
