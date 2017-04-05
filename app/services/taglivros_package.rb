class TaglivrosPackage
  def initialize(marketplace, params, logger)
    @params = params.dup
    validate_params!(:package_prefix, :shipping_zip, :products)

    @marketplace = marketplace
    @logger = logger
    @zip = @params.delete(:shipping_zip).gsub(/\D+/, "")
    @package_prefix = @params.delete(:package_prefix)

    build_packages
  end

  def to_h(quotations_class = Quotations)
    quotations = @packages.flat_map do |(package, products)|
      params = @params.merge(package: package, shipping_zip: @zip, products: products)
      quotations_class.new(@marketplace, params, @logger).to_a
    end

    log("number of quotations: #{quotations.size}")

    results = quotations.group_by(&:package).inject({}) do |memo, (package, quotations)|
      memo[package] = sum(quotations)
      memo
    end

    results[:total_packages] = results.keys.size
    results[:total_quotations] = quotations.size
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

  def build_packages
    kits, others = @params[:products].partition{|p| p[:shipping_tags].to_s.include?("kit") }
    @packages = {}
    kits.each_with_index do |product, i|
      @packages[ [@package_prefix, "%02i" % (i + 1)].join("-") ] = [product]
    end

    if others.size > 0
      @packages[[@package_prefix, "%02i" % (kits.size + 1)].join("-")] = others
    end

    log("number of packages: #{@packages.size}")
    @packages
  end

  def sum(quotations)
    quotations.group_by { |quote| quote.delivery_type_slug }.inject([]) do |memo, (_, quotations)|
      quotation = quotations.max_by { |quotation| quotation.deadline }.dup
      quotation.package = nil
      quotation.price = quotations.map { |quotation| quotation.name == "Impresso" ? 0 : quotation.price }.sum.to_f

      memo << quotation
      memo
    end
  end

  def log(message)
    @logger.tagged(self.class.name) { @logger.info(message) }
  end
end
