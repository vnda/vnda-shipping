class AddSingleCorreiosZipcodeJob
  include Sidekiq::Worker
  sidekiq_options :retry => true

  def perform(shop_id, options = {})
    Correios::Calculate.new(shop_id, options).single_call(options)
  end
end
