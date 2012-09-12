module Spree
  Order.class_eval do
    attr_accessible :amazon_fps_sender_token_id,:amazon_fps_status,:amazon_fps_transaction_id,:amazon_fps_request_id

    checkout_flow do
      go_to_state :address
      go_to_state :delivery
      go_to_state :payment, :if => lambda { |order| order.payment_required? }
      # since we've got the amazon-branded button shown on the payment page, skip the confirmation step
      go_to_state :complete_with_failed_amazon_payment, :if => lambda { |order| order.payment && order.payment.failed? && order.amazon_fps_status == 'FAILURE' }

      go_to_state :confirm, :if => lambda { |order| order.confirmation_required? }

      go_to_state :complete
      remove_transition :from => :delivery, :to => :confirm
    end

    # Spree chooses the first payment in the list.
    # I believe it'd be more accurate to choose the one w/ the latest activity
    def payment 
      payments.order(:updated_at).last
    end

    def amazon_fps?
      payment && payment.payment_method.kind_of?(Spree::Billing::AmazonFps)
    end
  end
end
