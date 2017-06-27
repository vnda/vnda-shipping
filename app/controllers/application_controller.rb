class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :instrument_requests, :require_authentication, except: :status

  def status
    render text: 'OK'
  end

  private

  def success_redirect(*args)
    opts = args.extract_options!
    key = "#{params[:controller]}.#{params[:action]}"
    notice = I18n.t(key, scope: [:notices])
    redirect_to(*args, opts.reverse_merge(notice: notice))
  end

  def instrument_requests
    I.increment("requests")
  end

  def require_authentication
    if Rails.env == "production"
      authenticate_or_request_with_http_basic do |name, password|
        name == ENV['HTTP_USER'] && password == ENV['HTTP_PASSWORD']
      end
    end
  end
end
