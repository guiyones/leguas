require "test_helper"

class SessionsFlowTest < ActionDispatch::IntegrationTest
  test "sem sessão, manda pro login" do
    get root_url

    assert_redirected_to new_session_url
  end

  test "pedir código cria o usuário se preciso e envia o email" do
    assert_difference -> { User.count } => 1, -> { AuthToken.count } => 1 do
      assert_enqueued_emails 1 do
        post auth_tokens_url, params: { email_address: "nova@leguas.test" }
      end
    end

    assert_redirected_to new_auth_tokens_validations_url
  end

  test "email inválido volta pro login com alerta" do
    post auth_tokens_url, params: { email_address: "nada" }

    assert_redirected_to new_session_url
    assert_equal "Esse email não parece certo, viajante.", flash[:alert]
  end

  test "código certo abre sessão e volta pra página pedida" do
    get root_url
    sign_in :viajante

    assert_redirected_to root_url
  end

  test "código errado volta pra validação" do
    post auth_tokens_url, params: { email_address: users(:viajante).email_address }
    post auth_tokens_validations_url, params: { code: "000000" }

    assert_redirected_to new_auth_tokens_validations_url
    assert_equal "Código inválido ou expirado", flash[:alert]
    assert cookies[:session_token].blank?
  end

  test "sair encerra a sessão" do
    sign_in :viajante

    delete session_url

    assert_redirected_to new_session_url
    get root_url
    assert_redirected_to new_session_url
  end

  test "quem já está logado não vê o login" do
    sign_in :viajante

    get new_session_url

    assert_redirected_to root_url
  end
end
