class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session

  private

  def render_success
    json = { type: 'success' }
    render json: json, status: 200
  end

  def render_error(message, code, status = 400)
    render json: { type: 'error',
      data: {
        message: message,
        code: Bridge::ErrorCodes::const_get(code)
      }
    },
    status: status
  end

  def render_not_found
    render :file => "#{Rails.root}/public/404", :layout => false, :status => 404, :formats => [:html,:png], :content_type => 'text/html'
  end
end
