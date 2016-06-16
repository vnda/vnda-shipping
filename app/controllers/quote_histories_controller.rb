class QuoteHistoriesController < ApplicationController
  before_filter { @shop = Shop.find(params[:shop_id]) }
  before_action :set_period, only: [:show]

  def index
    @quotes = @shop.quotes.order("updated_at desc")
  end

  def show
    if @quote
      render :layout => false if params[:cart_id].present?
    else
      render "not_found", :layout => false
    end
  end

  private
    def set_period
      if params[:cart_id].present?
        @quote = @shop.quotes.where(cart_id: params[:cart_id].to_i).order("updated_at desc").first
      else
        @quote = @shop.quotes.find(params[:id])
      end
    end
end
