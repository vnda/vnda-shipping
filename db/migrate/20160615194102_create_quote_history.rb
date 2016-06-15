class CreateQuoteHistory < ActiveRecord::Migration
  def change
    create_table :quote_histories do |t|
      t.integer :shop_id
      t.integer :cart_id
      t.text :external_request
      t.text :external_response
      t.text :quotations
      t.timestamps
    end
  end
end
