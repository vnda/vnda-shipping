Rails.env.on(:any) do
  config.i18n.enforce_available_locales = false
  config.i18n.available_locales = ["pt-BR"]
  config.i18n.default_locale = :'pt-BR'
  config.autoload_paths += %W(#{config.root}/lib)

  config.action_dispatch.default_headers.merge!({
    'Access-Control-Allow-Origin' => 'http://www.floriculturaideal.com.br',
    'Access-Control-Allow-Origin' => 'https://www.floriculturaideal.com.br',
    'Access-Control-Allow-Origin' => 'http://floriculturaideal.vnda.com.br',
    'Access-Control-Allow-Origin' => 'https://floriculturaideal.vnda.com.br',
    'Access-Control-Allow-Origin' => 'http://retex.lvh.me',
    'Access-Control-Allow-Origin' => '*',
    'Access-Control-Request-Method' => '*'
  })

  config.active_job.queue_adapter = :sidekiq
end
