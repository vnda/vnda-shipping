class AddActionToZipRules < ActiveRecord::Migration
  def change
    add_column :zip_rules, :action, :string, null: false, default: "allow"
  end
end
