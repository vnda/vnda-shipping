class ZipRule < ActiveRecord::Base
  belongs_to :shipping_method

  scope :for_zip, -> zip { where('zip_rules.range @> ?', zip) }

  validate :validate_no_overlap

  private

  def validate_no_overlap
    return if shipping_method.blank? || range.blank?
    overlap = shipping_method.zip_rules
      .where('range && int4range(?, ?)', range.begin, range.end)
    errors.add(:range) if overlap.exists?
  end
end
