class AuthTokensController < ApplicationController
  def self.normalize_email(email_address)
    email_address.to_s.strip.downcase.presence
  end

  allow_unauthenticated_access
  rate_limit_sign_in by: -> { self.class.normalize_email(params[:email_address]) || request.remote_ip }
  rate_limit_sign_in_by_ip to: 20, within: 10.minutes

  def create
    user = User.find_or_initialize_by(email_address: params[:email_address])

    if user.save
      send_code_to(user)
      redirect_to new_auth_tokens_validations_path
    else
      redirect_to new_session_path, alert: "Esse email não parece certo, viajante."
    end
  end

  private
    def send_code_to(user)
      user.auth_tokens.where(used_at: nil).delete_all
      auth_token = user.auth_tokens.create!(expires_at: AuthToken::EXPIRATION.from_now)
      auth_token.deliver_later
      session[:otp_email_address] = user.email_address
      reveal_code_in_development(auth_token)
    end

    def reveal_code_in_development(auth_token)
      if Rails.env.development?
        flash[:otp_code] = auth_token.code
      end
    end
end
