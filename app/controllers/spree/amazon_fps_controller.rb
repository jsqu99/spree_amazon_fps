module Spree
  class AmazonFpsController < BaseController
    ssl_allowed

    respond_to :html

    def select_payment_options
      remit = Remit::API.new(Billing::AmazonFps.current[:access_key_id],
                             Billing::AmazonFps.current[:secret_access_key],
                             Billing::AmazonFps.current[:test_mode])

      puts "request host: #{request.host}/receive_amazon_fps_token"
      pipeline_options = {
#        :return_url => "https://#{request.host}/receive_amazon_fps_token",
        :return_url => "http://localhost:3000/receive_amazon_fps_token",
        :caller_reference => "#{Spree::Config[:site_name]}-#{current_order.number}-#{Time.now.to_i}",
        :transaction_amount => current_order.total.to_s
      }
      pipeline = remit.get_single_use_pipeline(pipeline_options)

      redirect_to pipeline.url
    end

    def receive_amazon_fps_token 
      puts "params: #{params.inspect}"
      # figure out what order this maps to
      order = Order.find_by_number params["callerReference"].split('-')[1]

      # attr_accessible for payments is only on the order, so i dont' believe I can 
      # do everything in the 'build'
      payment = order.payments.build
      payment.payment_method_id = Billing::AmazonFps.current.id
      payment.amount = order.total
      payment.save!

      order.amazon_fps_sender_token_id = params["tokenID"]
      order.save!
      payment.started_processing!
      payment.pend!

      payment.order.reload 
      # now attempt to capture
      payment.payment_method.capture(payment) # yuk
      payment.order.reload 

=begin

      if payment.completed?
        # clear out the cart
        order.next! and session[:order_id] = nil
        redirect_to order_path(order)
      else
        flash[:error] = "#{t('amazon_fps.problem_with_payment')}: #{order.amazon_fps_status}"
        redirect_to checkout_state_path(order.state)
      end
=end
        redirect_to order_path(order)
    end

    def receive_ipn
      binding.pry
    end
  end
end

