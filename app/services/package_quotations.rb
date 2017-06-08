class PackageQuotations
  SellerNotFound = Class.new(StandardError)

  def initialize(marketplace, params, logger)
    @params = params.dup
    validate_params!(:shipping_zip, :products)

    @marketplace = marketplace
    @logger = logger
    @zip = @params.delete(:shipping_zip).gsub(/\D+/, "")
  end

  def to_h
    semaphore = Concurrent::Semaphore.new(5)
    threads = []
    results = Concurrent::Hash.new({})

    @params[:products].each do |package, products|
      threads << Thread.new do
        ActiveRecord::Base.connection.pool.with_connection do
          semaphore.acquire

          params = @params.merge(package: package, shipping_zip: @zip, products: products)
          quotations = Quotations.new(find_shop(package), params, @logger)
          results[package] = sum(quotations.to_a)

          semaphore.release
        end
      end
    end
    threads.each(&:join)

    log(results)
    results[:total_packages] = results.keys.size
    results[:total_quotations] = results.sum { |_, quotations| quotations.size }
    results
  end

  protected

  def validate_params!(*names)
    mandatory_params = names.inject({}) { |memo, name| memo[name] = @params[name]; memo }
    unless mandatory_params.all? { |_, value| value.present? }
      message = mandatory_params.reject { |_, value| value.present? }.keys.to_sentence
      raise Quotations::BadParams, message
    end
  end

  def find_shop(tag)
    return @marketplace if tag.blank?

    shop = @marketplace.shops.includes(:marketplace).where(marketplace_tag: tag).first
    return shop if shop

    log("Shop not found for tag #{tag}")
    @marketplace
  end

  def sum(quotations)
    quotations.group_by { |quote| quote.delivery_type_slug }.inject([]) do |memo, (_, quotations)|
      quotation = quotations.max_by { |quotation| quotation.deadline }.dup
      quotation.package = nil
      quotation.price = quotations.map { |quotation| quotation.price }.sum.to_f

      memo << quotation
      memo
    end
  end

  def log(message)
    @logger.tagged(self.class.name) { @logger.info(message) }
  end
end
