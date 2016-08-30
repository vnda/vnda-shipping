class ZipcodeSpreadsheet < ActiveRecord::Base
  belongs_to :shop
  belongs_to :delivery_type
end
