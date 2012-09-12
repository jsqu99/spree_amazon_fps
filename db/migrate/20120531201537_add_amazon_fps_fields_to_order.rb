class AddAmazonFpsFieldsToOrder < ActiveRecord::Migration
  def change
    add_column :spree_orders, :amazon_fps_sender_token_id, :string
    add_column :spree_orders, :amazon_fps_status, :string
    add_column :spree_orders, :amazon_fps_transaction_id, :string
    add_column :spree_orders, :amazon_fps_request_id, :string
  end
end
