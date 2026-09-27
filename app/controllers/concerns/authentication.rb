module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :authenticated?
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end

    def require_unauthenticated_access(**options)
      allow_unauthenticated_access(**options)
      before_action :redirect_signed_in_user_to_root, **options
    end

    def rate_limit_sign_in(by:)
      rate_limit to: 10, within: 1.minute, only: :create, by: by,
        with: -> { redirect_to new_session_path, alert: "Muitas tentativas. Respira e tenta de novo daqui a um minuto." }
    end
  end

  private
    def authenticated?
      Current.session.present?
    end

    def require_authentication
      restore_authentication || request_authentication
    end

    def restore_authentication
      if user_session = find_session_by_cookie
        user_session.resume(user_agent: request.user_agent, ip_address: request.remote_ip)
        Current.session = user_session
      end
    end

    def find_session_by_cookie
      if token = cookies.signed[:session_token]
        Session.unexpired.find_by(token: token)
      end
    end

    def request_authentication
      session[:return_to_after_authenticating] = request.url
      redirect_to new_session_path
    end

    def redirect_signed_in_user_to_root
      if restore_authentication
        redirect_to root_path
      end
    end

    def post_authenticating_url
      session.delete(:return_to_after_authenticating) || root_url
    end

    def start_new_session_for(user)
      user.sessions.start!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |user_session|
        Current.session = user_session
        cookies.signed.permanent[:session_token] = {
          value: user_session.token, httponly: true, same_site: :lax, secure: Rails.env.production?
        }
      end
    end

    def terminate_session
      Current.session.destroy
      cookies.delete(:session_token)
    end
end
