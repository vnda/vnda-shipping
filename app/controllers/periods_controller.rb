class PeriodsController < ApplicationController
  before_filter { @shop = Shop.find(params[:shop_id]) }
  before_action :set_period, only: [:show, :edit, :update, :destroy]

  def index
    @periods = @shop.periods
  end

  def show
  end

  def new
    @period = @shop.periods.new
  end

  def edit
  end

  def create
    @period = @shop.periods.new(period_params)

    if @period.save
      redirect_to shop_period_path(@shop, @period), notice: 'Period was successfully created.'
    else
      render :new
    end
  end

  def update
    if @period.update(period_params)
      redirect_to shop_period_path(@shop, @period), notice: 'Period was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @period.destroy
    redirect_to shop_periods_path(@shop), notice: 'Period was successfully destroyed.'
  end

  private
    def set_period
      @period = Period.find(params[:id])
    end

    def period_params
      params.require(:period).permit(:name, :limit_time, :days_off)
    end
end
