class QuoteHistoriesController < ApplicationController
  before_filter { @shop = Shop.find(params[:shop_id]) }
  before_action :set_period, only: [:show]
  before_action :require_authentication, except: :show
  before_action :authenticate_with_token_or_password, only: :show

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

    def authenticate_with_token_or_password
      if params[:token].present?
        begin
          Shop.find_by!(token: params[:token])
        rescue ActiveRecord::RecordNotFound
          return head :unauthorized
        end
      else
        authenticate_or_request_with_http_basic do |name, password|
          name == ENV['HTTP_USER'] && password == ENV['HTTP_PASSWORD']
        end
      end
    end
end
