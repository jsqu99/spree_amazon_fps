module Spree
  class AmazonFpsController < BaseController
    ssl_allowed
    skip_before_filter :verify_authenticity_token

    respond_to :html

    def receive_amazon_fps_token
      # figure out what order this maps to
      order_number = params["callerReference"].split('-')[0]

      order = Spree::Order.find_by_number order_number

      SpreeAmazonFps::Receiver.receive_amazon_fps_token(order, params["tokenID"])

      flash.notice = t(:order_processed_successfully_amazon_fps)
      flash[:commerce_tracking] = "nothing special"
      redirect_to order_path(order)
    end

    # possibly make some comparisons w/ the tokens we receive w/ what we have in the order model for security
    #=> {"transactionAmount"=>"USD 110.00",
    # "signatureMethod"=>"RSA-SHA1",
    # "transactionId"=>"176S9C7KKD5MF9GH13G721JMK2AP185VLR8",
    # "buyerEmail"=>"jsquires@railsdog.com",
    # "recipientEmail"=>"jeff.squires@gmail.com",
    # "buyerName"=>"Jeff Squires Rails Dog",
    # "transactionDate"=>"1347421609",
    # "statusMessage"=>
    #  "The transaction was successful and the payment instrument was charged.",
    # "statusCode"=>"Success",
    # "operation"=>"PAY",
    # "recipientName"=>"JEFFREY D SQUIRES",
    # "notificationType"=>"TransactionStatus",
    # "signatureVersion"=>"2",
    # "transactionStatus"=>"SUCCESS",
    # "signature"=>
    #  "iFROJDEsIPeY+f3kFmNx4UaAzyLlCeC6ZX3G49anJNbox5c1sV+PKmPW4wWJrNqz6nmH9m/hunEp\npBEEv+xUHgzErQVxkr5hxzV5YyV8LoZYrKyN+GE/VDw1QceBpVm9KCbFeUUmbrfs4N2itTwqucRA\nVhXC2W9nd/lSNLilrUw=",
    # "certificateUrl"=>
    #  "https://fps.sandbox.amazonaws.com/certs/090911/PKICert.pem?requestId=15n5aynuucub6e679c4uvz33a2u86j2diq484brzw4stvle",
    # "paymentMethod"=>"CC",
    # "callerReference"=>"R641358124-1347421615",
    # "controller"=>"spree/amazon_fps",
    # "action"=>"receive_ipn"}
    #
    def receive_ipn
      caller_reference, transaction_id, transaction_status = params["callerReference"], params["transactionId"], params["transactionStatus"]

      order_number = caller_reference.split('-')[0]

      order = Spree::Order.find_by_number order_number

      if order.blank?
        Rails.logger.errror "Received unknown order from Amazon IPN.  Caller Reference: #{params['callerReference']}"
      else
        # amazon keeps calling us over and over again in some circumstances, so prevent that from propagating us
        SpreeAmazonFps::Receiver.receive_ipn(order, transaction_id, transaction_status) unless order.completed?
      end

      render :nothing => true
    end
  end
end

