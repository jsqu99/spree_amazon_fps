module Spree
  module Admin
    class AmazonFpsController <  Spree::Admin::BaseController

      respond_to :html

      def capture
        remit = Remit::API.new(Billing::AmazonFps.current[:access_key_id],
                               Billing::AmazonFps.current[:secret_access_key],
                               Billing::AmazonFps.current[:test_mode])

        order = Order.find_by_number params["order_id"]

        request = Remit::Pay::Request.new(:caller_reference => "#{order.number}-#{Time.now.to_i}",
                                          :charge_fee_to    => 'Caller',
                                          :sender_token_id  => order.amazon_fps_sender_token_id,
                                          :transaction_amount => Remit::RequestTypes::Amount.new(:value => order.total.to_s, :currency_code => 'USD'))

        response = remit.pay(request)

        puts response.pay_result.inspect

        #TODO: these are the possible statuses.  react accordingly: %w(cancelled failure pending reserved success)

        order.update_attributes(:amazon_fps_status => response.pay_result.transaction_status, :amazon_fps_transaction_id => response.pay_result.transaction_id)

        if order.transaction_status == 'success'
          payment = order.payments.detect {|p| p.payment_method == Billing::AmazonFps && p.pending?}
          payment.complete! if payment
        end

        redirect_to admin_orders_path
      end
    end
  end
end
