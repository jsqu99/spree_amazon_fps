Deface::Override.new(:virtual_path => 'spree/checkout/_payment',
                     :name => 'add_amazon_button_to_payment_form',
                     :insert_top => '[data-hook="checkout_payment_step"]',
                     :text => %(
    <p>
      <label>
        <%= image_tag 'http://g-ecx.images-amazon.com/images/G/01/cba/b/sg3.jpg' %>
      </label>
    </p>

)
)
