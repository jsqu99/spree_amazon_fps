module Spree
  CheckoutController.class_eval do
    def before_payment
      return unless request.put?
      
      current_order.payments.destroy_all 

      o = Spree::Order.new(params[:order])
      payment_method = o.payments.first.payment_method

      if (payment_method.kind_of?(Spree::Billing::AmazonFps))
        remit = Remit::API.new(Billing::AmazonFps.current[:access_key_id],
                               Billing::AmazonFps.current[:secret_access_key],
                               Billing::AmazonFps.current[:test_mode])

        Rails.logger.debug "request host: #{request.host}/receive_amazon_fps_token"

        pipeline_options = {
          #        :return_url => "https://#{request.host}/receive_amazon_fps_token",
          :return_url => "http://localhost:3000/receive_amazon_fps_token",
          :caller_reference => "#{current_order.number}-#{Spree::Config[:site_name]}-#{Time.now.to_i}",
          :transaction_amount => current_order.total.to_s
        }
        pipeline = remit.get_single_use_pipeline(pipeline_options)

        redirect_to pipeline.url
      end
    end
  end
end
