Rails.env.on(:any) do
  config.i18n.enforce_available_locales = false
  config.i18n.available_locales = ["pt-BR"]
  config.i18n.default_locale = :'pt-BR'
  config.autoload_paths += %W(#{config.root}/lib)
end
