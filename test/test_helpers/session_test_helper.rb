module SessionTestHelper
  def sign_in(user)
    user = users(user) unless user.is_a?(User)

    post auth_tokens_url, params: { email_address: user.email_address }
    post auth_tokens_validations_url, params: { code: user.auth_tokens.order(:created_at).last.code }

    assert cookies[:session_token].present?, "sign_in não abriu sessão"
  end
end
