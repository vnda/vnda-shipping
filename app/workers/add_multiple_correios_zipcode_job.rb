class AddMultipleCorreiosZipcodeJob
  include Sidekiq::Worker
  sidekiq_options :retry => true

  def perform(shop_id, options = {})
    Correios::Calculate.new(shop_id, options).multiple_call
  end
end
