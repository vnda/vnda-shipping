## => CSV FORMAT
## ZipCodeStart,ZipCodeEnd,WeightStart,WeightEnd,AbsoluteMoneyCost,PricePercent,
## PriceByExtraWeight,MaxVolume,TimeCost,Country,MinimumValueInsurance,
## operationType,restrictedFreights
##
class Correios::Calculate
  include HTTParty

  def initialize shop_id, options={}
    @shop                     = Shop.find(shop_id)
    @service_code             = options[:service_code]    || 41106  # PAC Varejo
    @enterprise_code          = options[:enterprise_code] || nil
    @enterprise_pass          = options[:enterprise_pass] || nil
    @zipcode_start            = options[:zipcode_start]
    @track_ceps               = TrackCep.where(service_code: @service_code) || TrackCep.where(service_code: 0)
    @weight_tracks            = TrackWeight.where(service_code: @service_code) || TrackWeight.where(service_code: 0)
    @response                 = nil
  end

  def calculate
    @track_ceps.each do |cep|
      @weight_tracks.each do |weight, index|
        cep.tracks(&:map).each do |track|
          weight.medium.each do |medium_track|
            @response = HTTParty.get(url(@service_code, @enterprise_code, @enterprise_pass, unmask_cep(@zipcode_start), unmask_cep(cep.tracks[2]), medium_track))
            puts @response.body, @response.code, @response.message, @response.headers.inspect
          end
        end
      end
    end
  end

  private
  def unmask_cep cep
    cep.tr '-', ''
  end

  def url service_code, enterprise, pass, zipcode_start, zipcode_end, weight
    "http://ws.correios.com.br/calculador/CalcPrecoPrazo.aspx?nCdEmpresa=#{enterprise}&sDsSenha=#{pass}&sCepOrigem=#{zipcode_start}&sCepDestino=#{zipcode_end}&nVlPeso=#{weight}&nCdFormato=1&nVlComprimento=16&nVlAltura=2&nVlLargura=11&sCdMaoPropria=n&nVlValorDeclarado=0.50&sCdAvisoRecebimento=n&nCdServico=#{service_code}&nVlDiametro=0&StrRetorno=xml"
  end
end


