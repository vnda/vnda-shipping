class PackageQuotations
  def initialize(marketplace, params)
    raise Quotations::BadParams unless params[:shipping_zip] && params[:products]

    @marketplace = marketplace
    @params = params
    @zip = @params.delete(:shipping_zip).gsub(/\D+/, "")

    build_packages
  end

  def to_a(quotations_class = Quotations)
    quotations = @packages.flat_map do |shop, products|
      quotations_class.new(shop, @params.merge(shipping_zip: @zip, products: products)).to_a
    end

    sum(quotations)
  end

  protected

  def build_packages
    products = @params[:products].map do |product|
      product[:shop] = @marketplace.shops.where(marketplace_tag: product[:tags]).first || @marketplace
      product
    end

    @packages = products.group_by { |product| product.delete(:shop) }
  end

  def sum(quotations)
    quotations.group_by { |quote| quote.delivery_type_slug }.inject([]) do |memo, (slug, quotations)|
      quotation = quotations.max_by { |quotation| quotation.deadline }
      quotation.price = quotations.map { |quotation| quotation.price.to_d }.sum.to_f

      memo << quotation
      memo
    end
  end
end
