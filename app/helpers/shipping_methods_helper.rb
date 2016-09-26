module ShippingMethodsHelper
  def input_shop_correios_code shop, builder
    if shop.correios_code.present?
      builder.text_field :enterprise_code, @shop.correios_code, class: 'form-control', disabled: true
    else
      builder.text_field :enterprise_code, class: 'form-control'
    end
  end

  def input_shop_correios_pass shop, builder
    if shop.correios_password.present?
      builder.text_field :enterprise_pass, @shop.correios_password, class: 'form-control', disabled: true
    else
      builder.text_field :enterprise_pass, class: 'form-control'
    end
  end

  def safety_margin_select
   [
     ['5%', 5], ['10%', 10], ['15%', 15], ['20%', 20], ['25%', 25]
   ]
  end
end
