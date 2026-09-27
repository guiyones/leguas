class AuthTokenMailer < ApplicationMailer
  def otp(auth_token)
    @code = auth_token.code
    @expires_in = auth_token.expires_at - Time.current

    mail(to: auth_token.user.email_address, subject: "Seu código pra entrar no Léguas")
  end
end
