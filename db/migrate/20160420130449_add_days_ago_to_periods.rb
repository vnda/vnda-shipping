class AddDaysAgoToPeriods < ActiveRecord::Migration
  def change
    add_column :periods, :days_ago, :integer, default: 0
  end
end
