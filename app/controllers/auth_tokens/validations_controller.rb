class AuthTokens::ValidationsController < ApplicationController
  require_unauthenticated_access only: :new
  allow_unauthenticated_access only: :create
  rate_limit_sign_in by: -> { session[:otp_email_address] || request.remote_ip }

  def new
  end

  def create
    if auth_token = AuthToken.lookup(email_address: session[:otp_email_address], code: params[:code])
      auth_token.use!
      session.delete(:otp_email_address)
      start_new_session_for(auth_token.user)
      redirect_to post_authenticating_url
    else
      redirect_to new_auth_tokens_validations_path, alert: "Código inválido ou expirado"
    end
  end
end
