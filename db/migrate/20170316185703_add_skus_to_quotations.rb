class AddSkusToQuotations < ActiveRecord::Migration
  def change
    add_column :quotations, :skus, :string, array: true, null: false, default: []
  end
end
