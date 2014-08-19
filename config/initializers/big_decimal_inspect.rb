class BigDecimal
  def inspect
    "#{self.class.name}(#{to_s})"
  end
end
