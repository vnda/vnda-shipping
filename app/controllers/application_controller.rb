class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

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
end
