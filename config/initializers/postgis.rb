ActiveRecord::ConnectionAdapters::PostgreSQLColumn.class_eval do

  def spatial?
    type == :spatial || type == :geography
  end
end
