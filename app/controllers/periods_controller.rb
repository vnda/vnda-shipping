class PeriodsController < ApplicationController
  before_filter { @shop = Shop.find(params[:shop_id]) }
  before_action :set_period, only: [:show, :edit, :update, :destroy]

  # GET /periods
  def index
    @periods = @shop.periods
  end

  # GET /periods/1
  def show
  end

  # GET /periods/new
  def new
    @period = @shop.periods.new
  end

  # GET /periods/1/edit
  def edit
  end

  # POST /periods
  def create
    @period = @shop.periods.new(period_params)

    if @period.save
      redirect_to shop_period_path(@shop, @period), notice: 'Period was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /periods/1
  def update
    if @period.update(period_params)
      redirect_to @period, notice: 'Period was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /periods/1
  def destroy
    @period.destroy
    redirect_to shop_periods_path(@shop), notice: 'Period was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_period
      @period = Period.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def period_params
      params.require(:period).permit(:name, :limit_time, :days_off)
    end
end
