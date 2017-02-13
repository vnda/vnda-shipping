Rails.application.config.action_dispatch.default_headers.merge!(
  "Access-Control-Allow-Origin" => "*",
  "Access-Control-Request-Method" => "*"
)
