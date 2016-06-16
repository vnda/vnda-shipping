class QuoteHistoriesController < ApplicationController
  before_filter { @shop = Shop.find(params[:shop_id]) }
  before_action :set_period, only: [:show]

  def index
    @quotes = @shop.quotes.order("updated_at desc")
  end

  def show
  end

  private
    def set_period
      @quote = @shop.quotes.find(params[:id])
    end
end
