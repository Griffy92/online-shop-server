class CreateOrdersProducts < ActiveRecord::Migration[5.2]
  def change
    create_table :orders_products, :id => false do |t|
      t.integer :order_id
      t.integer :product_id
      t.timestamps
    end
  end
end
