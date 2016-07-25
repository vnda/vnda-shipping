class AddDeadlineToPlaces < ActiveRecord::Migration
  def change
    add_column :places, :deadline, :integer, null: false, default: 0
  end
end
