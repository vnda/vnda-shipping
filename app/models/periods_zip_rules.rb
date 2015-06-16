# == Schema Information
#
# Table name: periods_zip_rules
#
#  id          :integer          not null, primary key
#  period_id   :integer
#  zip_rule_id :integer
#  created_at  :datetime
#  updated_at  :datetime
#

class PeriodsZipRules < ActiveRecord::Base
end
