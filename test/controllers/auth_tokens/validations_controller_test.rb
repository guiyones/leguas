require "test_helper"

class AuthTokens::ValidationsControllerTest < ActionDispatch::IntegrationTest
  test "sem pendência de código redireciona pro login" do
    get new_auth_tokens_validations_url

    assert_redirected_to new_session_url
  end

  test "código com espaço entre os dígitos ainda funciona" do
    user = users(:viajante)
    post auth_tokens_url, params: { email_address: user.email_address }
    code = user.auth_tokens.order(:created_at).last.code
    spaced_code = "#{code[0..2]} #{code[3..5]}"

    post auth_tokens_validations_url, params: { code: spaced_code }

    assert cookies[:session_token].present?
  end
end
