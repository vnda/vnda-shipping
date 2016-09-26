class AddMultipleCorreiosZipcodeJob < ActiveJob::Base
  queue_as :default

  def perform shop_id, options={}
    shop = Shop.find(shop_id)
    Correios::Calculate.multiple_call!(shop.id, options)
  end
end
