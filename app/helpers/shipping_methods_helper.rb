module ShippingMethodsHelper
  def input_shop_correios_code shop
    if shop.correios_code.present?
      text_field_tag :correios_code, @shop.correios_code, class: 'form-control', disabled: true
      text_field_tag :correios_code, nil, class: 'form-control'
    else
      text_field_tag :correios_code, nil, class: 'form-control'
    end
  end

  def input_shop_correios_pass shop
    if shop.correios_password.present?
      text_field_tag :correios_pass, @shop.correios_password, class: 'form-control', disabled: true
    else
      text_field_tag :correios_pass, nil, class: 'form-control'
    end
  end

  def safety_margin_select
   [
     ['5%', 5], ['10%', 10], ['15%', 15], ['20%', 20], ['25%', 25]
   ]
  end
end
