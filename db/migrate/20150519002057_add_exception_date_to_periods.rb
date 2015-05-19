class AddExceptionDateToPeriods < ActiveRecord::Migration
  def change
    add_column :periods, :exception_date, :text
  end
end
