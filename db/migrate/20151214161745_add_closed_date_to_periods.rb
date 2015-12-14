class AddClosedDateToPeriods < ActiveRecord::Migration
  def change
    add_column :periods, :closed_date, :text
  end
end
