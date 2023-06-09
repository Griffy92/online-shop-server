class CreateCartItems < ActiveRecord::Migration[5.2]
  def change
    create_table :cart_items do |t|
      t.integer :order_id
      t.integer :product_id
      t.integer :quantity, :default => 1
      t.timestamps
    end
  end
end
