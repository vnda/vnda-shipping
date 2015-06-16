# == Schema Information
#
# Table name: block_rules
#
#  id                 :integer          not null, primary key
#  shipping_method_id :integer          not null
#  range              :int4range        not null
#

class BlockRule < ActiveRecord::Base
  belongs_to :shipping_method
  has_one :shop, through: :shipping_method

  scope :for_zip, -> zip { where('block_rules.range @> ?', zip) }

  attr_writer :min, :max
  def min; @min ||= range.try(:min) end
  def max; @max ||= range.try(:max) end

  before_validation do
    self.range = Range.new(*[min, max].map { |v| v.to_s.gsub(/\D/, '').to_i })
  end
end
