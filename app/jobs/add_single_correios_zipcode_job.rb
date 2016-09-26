class AddSingleCorreiosZipcodeJob < ActiveJob::Base
  queue_as :default

  def perform shop_id, options={}
    shop = Shop.find(shop_id)
    Correios::Calculate. single_call!(shop.id, options)
  end
end
