module Spree
  module Billing
    class AmazonFps < BillingIntegration
      preference :test_mode, :boolean, :default => true
      preference :access_key_id, :string
      preference :secret_access_key, :string  

      attr_accessible :preferred_test_mode, :preferred_access_key_id, :preferred_secret_access_key, :preferred_server  #this last one must be a spree bug
      def [](config_setting)
        begin
          self.send("preferred_#{config_setting}")
        rescue NoMethodError
          super
        end
      end
      
      def self.current
        self.where(:type => self.to_s, :environment => Rails.env, :active => true).first
      end

      # this was all copied from Spree::PaymentMethod::Check
      # steal fleshing out how all of this works
      def actions
        %w{capture void}
      end

      # Indicates whether its possible to capture the payment
      def can_capture?(payment)
        ['checkout', 'pending'].include?(payment.state)
      end

      # Indicates whether its possible to void the payment.
      def can_void?(payment)
        payment.state != 'void'
      end

      def capture(payment)
        remit = Remit::API.new(Billing::AmazonFps.current[:access_key_id],
                               Billing::AmazonFps.current[:secret_access_key],
                               Billing::AmazonFps.current[:test_mode])

        order = payment.order

        request = Remit::Pay::Request.new(:caller_reference => "#{order.number}-#{Time.now.to_i}",
                                          :charge_fee_to    => 'Caller',
                                          :sender_token_id  => order.amazon_fps_sender_token_id,
                                          :transaction_amount => Remit::RequestTypes::Amount.new(:value => order.total.to_s, :currency_code => 'USD'))

        response = remit.pay(request)

        puts response.pay_result.inspect

        #these are the possible statuses. Cancelled Failure Pending Reserved Success)
        order.update_attributes(:amazon_fps_status => response.pay_result.transaction_status, :amazon_fps_transaction_id => response.pay_result.transaction_id)


=begin
        case (order.amazon_fps_status.present? && order.amazon_fps_status.downcase)
        when false             # some errors leave the status empty :-(
          payment.void!
        when 'success'
          payment.complete!
        when 'failure'
          payment.failure!
        when 'cancelled'
          payment.void!
        end

        payment.completed?
=end

        # here we'll update the order state to 'pending-capture-confirm'
        true
      end

      def void(payment)
        payment.update_attribute(:state, 'pending') if payment.state == 'checkout'
        payment.void
        true
      end

      def source_required?
        false
      end
    end
  end
end
