require "application_system_test_case"

class OnboardingTest < ApplicationSystemTestCase
  test "enter no nome não pula direto pro fim do formulário" do
    visit root_url
    fill_in "Email", with: "estreante@leguas.test"
    click_on "Receber código"
    assert_text "CÓDIGO"
    fill_in "Código de 6 dígitos", with: User.find_by(email_address: "estreante@leguas.test").auth_tokens.last.code
    click_on "Entrar"

    assert_text "Qual o seu nome, viajante?"
    fill_in "Seu nome de viajante", with: "Nina"
    find_field("Seu nome de viajante").send_keys(:enter)

    assert_text "Escolha seu viajante"
  end
end
