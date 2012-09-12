module Spree
  Order.class_eval do
    attr_accessible :amazon_fps_sender_token_id,:amazon_fps_status,:amazon_fps_transaction_id,:amazon_fps_request_id
  end
end
