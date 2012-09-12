Spree::Core::Engine.routes.draw do
  # Add your extension routes here
  match '/checkout/amazon_fps', :to => 'amazon_fps#select_payment_options', :as => :pay_using_amazon_fps
  match '/receive_amazon_fps_token', :to => 'amazon_fps#receive_amazon_fps_token'
  match '/admin/capture_amazon_fps_payment/:order_id', :to => 'admin/amazon_fps#capture', :as => :capture_amazon_fps_payment

  post '/receive_ipn', :to => 'amazon_fps#receive_ipn'
end
