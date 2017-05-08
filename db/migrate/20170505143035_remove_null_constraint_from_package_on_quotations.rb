class RemoveNullConstraintFromPackageOnQuotations < ActiveRecord::Migration
  def up
    change_column_null :quotations, :package, true
  end

  def down
    # can't be rolled back
  end
end
