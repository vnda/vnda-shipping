class ShippingMethod < ActiveRecord::Base
  belongs_to :shop
  has_many :zip_rules, dependent: :destroy
  accepts_nested_attributes_for :zip_rules, allow_destroy: true, reject_if: :all_blank

  validates :name, presence: true
  validates_associated :zip_rules
end
