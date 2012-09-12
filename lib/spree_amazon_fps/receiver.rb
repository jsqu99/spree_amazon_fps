module SpreeAmazonFps
  class Receiver

    # TODO: handle errors such as these: http://localhost:3000/receive_amazon_fps_token?errorMessage=User+Error%3A+The+pipeline+was+aborted+and+restarted&signatureMethod=RSA-SHA1&status=NP&signatureVersion=2&signature=oNs5QXJdeQ1u2EqHgtlMPrgHhKEmUh8kOPi5%2BCB1j9pqf6SwbCBSfF7nLjbBxskzRgrybvQCpQ6q%0AiLKtSwmRO3DYYTJmgIoe2ZJ9ptJOtD%2FUY0en%2FyP5V5dcJCPjThjEbJ%2FPPZxEdRQLsM4LyRzmH%2FOE%0Ag3ChqhtVADbI%2B0%2F20Fk%3D&certificateUrl=https%3A%2F%2Ffps.sandbox.amazonaws.com%2Fcerts%2F090911%2FPKICert.pem%3FrequestId%3Dbjykc5z7jagpe7o43lwji2gv1tsa30s4fpgbsfpvd8gh87p4jle

    def self.receive_amazon_fps_token(order, token_id)
      #Rails.logger.debug "params: #{params.inspect}"

      # attr_accessible for payments is only on the order, so i dont' believe I can 
      # do everything in the 'build'
      payment = order.payments.build
      payment.payment_method_id = Spree::Billing::AmazonFps.current.id
      payment.amount = order.total
      payment.save!

      # save the relevant 
      order.amazon_fps_sender_token_id = token_id
      order.save!

      payment.started_processing!
      payment.pend!

      payment.order.reload 

      # now attempt to capture
      payment.payment_method.capture(payment) # yuk
      payment.order.reload 
    end

    def self.receive_ipn(order, transaction_id, transaction_status)
      order.update_attributes(:amazon_fps_status => transaction_status)

      #these are the possible statuses. Cancelled Failure Pending Reserved Success)

      case transaction_status
        when "SUCCESS"
          order.payment.complete!
          order.next
        when "FAILURE"
          order.payment.started_processing! # cheating since we can't go from pending to failure
          order.payment.failure!
          order.complete_with_failed_amazon_payment!
      end
    end
  end
end
