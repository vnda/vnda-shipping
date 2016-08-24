## => Params
## ZipCodeStart,ZipCodeEnd,WeightStart,WeightEnd,AbsoluteMoneyCost,PricePercent,
## PriceByExtraWeight,MaxVolume,TimeCost,Country,MinimumValueInsurance,
## operationType,restrictedFreights
##
class Correios::Calculate
  include HTTParty

  def initialize options={}
    @service_code             = options[:service_code] || 40010
    @enterprise_code          = options[:enterprise_code]
    @enterprise_pass          = options[:enterprise_pass]
    @zipcode_start            = options[:zipcode_start]
    @zipcode_end              = options[:zipcode_end]
    @weight_start             = options[:weight_start]
    @weight_end               = options[:weight_end]
    @absolute_money_cost      = options[:absolute_money_cost]
    @price_percent            = options[:price_percent]
    @price_by_extra_weight    = options[:price_by_extra_weight]
    @max_volume               = options[:max_volume]
    @time_cost                = options[:time_cost]
    @country                  = options[:country]
    @minimum_value_insurance  = options[:minimum_value_insurance]
    @operation_type           = options[:operation_type]
    @restricted_freights      = options[:restricted_freights]
    @response = nil
  end

  def execute
    @response = HTTParty.get(url)
    puts @response.body, @response.code, @response.message, @response.headers.inspect
  end

  private

  def url
    "http://ws.correios.com.br/calculador/CalcPrecoPrazo.aspx?nCdEmpresa=#{@enterprise_code}&sDsSenha=#{@enterprise_pass}&sCepOrigem=#{@zipcode_start}&sCepDestino=#{@zipcode_end}&nVlPeso=#{@weight_start}&nCdFormato=1&nVlComprimento=16&nVlAltura=2&nVlLargura=11&sCdMaoPropria=n&nVlValorDeclarado=0.50&sCdAvisoRecebimento=n&nCdServico=#{@service_code}&nVlDiametro=0&StrRetorno=xml"
  end
end

{
  nCdEmpresa => [ String

    Seu código administrativo junto à ECT. O código está disponível no corpo do contrato firmado com os Correios.
    Obrigatorio? Não, mas o parâmetro tem que ser passado mesmo vazio.
  ]

  sDsSenha => [ String
    Senha para acesso ao serviço, associada ao seu código administrativo.
    A senha inicial corresponde aos 8 primeiros dígitos do CNPJ informado no contrato.
    A qualquer momento, é possível alterar a senha no endereço
    Obrigatorio? Não, mas o parâmetro tem que ser passado mesmo vazio.
  ]

}

