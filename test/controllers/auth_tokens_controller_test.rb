require "test_helper"

class AuthTokensControllerTest < ActionDispatch::IntegrationTest
  test "pedir código de novo invalida o código anterior" do
    user = users(:viajante)

    post auth_tokens_url, params: { email_address: user.email_address }
    first_code = user.auth_tokens.order(:created_at).last.code

    post auth_tokens_url, params: { email_address: user.email_address }

    assert_nil AuthToken.lookup(email_address: user.email_address, code: first_code)
  end

  test "normaliza o email pro rate limit: espaços e maiúsculas viram a mesma chave" do
    assert_equal "viajante@leguas.test", AuthTokensController.normalize_email(" Viajante@Leguas.Test ")
    assert_nil AuthTokensController.normalize_email("   ")
    assert_nil AuthTokensController.normalize_email(nil)
  end
end
