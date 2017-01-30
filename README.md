```ruby
params = {
  "origin_zip" => "03320000",
  "shipping_zip" => "80035120",
  "order_total_price" => 186.0,
  "aditional_deadline" => nil,
  "aditional_price" => nil,
  "products" => [
    {
      "sku" => "1510",
      "price" => 50.0,
      "height" => 2,
      "length" => 16,
      "width" => 11,
      "weight" => 0.35,
      "quantity" => 2
    },
    {
      "sku" => "1508B",
      "price" => 43.0,
      "height" => 2,
      "length" => 16,
      "width" => 11,
      "weight" => 0.4,
      "quantity" => 2
    }
  ],
  "token" => "04ca2b612050002cdee6fcbd8d5cd3f0",
  "api" => {
    "origin_zip" => "90570070",
    "shipping_zip" => "34000000",
    "order_total_price" => 186.0,
    "aditional_deadline" => nil,
    "aditional_price" => nil,
    "products" => [
      {
        "sku" => "1510",
        "price" => 50.0,
        "height" => 2,
        "length" => 16,
        "width" => 11,
        "weight" => 0.35,
        "quantity" => 2
      },
      {
        "sku" => "1508B",
        "price" => 43.0,
        "height" => 2,
        "length" => 16,
        "width" => 11,
        "weight" => 0.4,
        "quantity" => 2
      }
    ]
  }
}

uri = URI('http://vnda-shipping.herokuapp.com/quote?token=5536ed5b0e2c31b7ae477d2d9f0099a9')
req = Net::HTTP::Post.new(uri, initheader = { 'Content-Type' => 'application/json' })
req.body = params.to_json
res = Net::HTTP.start(uri.hostname, uri.port) do |http|
  http.request(req)
end
```

```ruby
{:calc_preco_prazo_response=>{:calc_preco_prazo_result=>{:servicos=>{:c_servico=>[{:codigo=>"40010", :valor=>"33,54", :prazo_entrega=>"1", :valor_mao_propria=>"0,00", :valor_aviso_recebimento=>"0,00", :valor_valor_declarado=>"2,04", :entrega_domiciliar=>nil, :entrega_sabado=>nil, :erro=>"0", :msg_erro=>nil, :valor_sem_adicionais=>"31,50", :obs_fim=>nil}, {:codigo=>"41106", :valor=>"20,84", :prazo_entrega=>"6", :valor_mao_propria=>"0,00", :valor_aviso_recebimento=>"0,00", :valor_valor_declarado=>"2,04", :entrega_domiciliar=>"S", :entrega_sabado=>"N", :erro=>"0", :msg_erro=>nil, :valor_sem_adicionais=>"18,80", :obs_fim=>nil}]}}, :@xmlns=>"http://tempuri.org/"}}
```
