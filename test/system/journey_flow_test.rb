require "application_system_test_case"

class JourneyFlowTest < ApplicationSystemTestCase
  test "novo viajante entra, caminha 8 km e ganha o primeiro carimbo" do
    visit root_url
    fill_in "Email", with: "estreante@leguas.test"
    click_on "Receber código"

    assert_text "CÓDIGO"
    fill_in "Código de 6 dígitos", with: User.find_by(email_address: "estreante@leguas.test").auth_tokens.last.code
    click_on "Entrar"

    assert_text "Qual o seu nome, viajante?"
    fill_in "Seu nome de viajante", with: "Nina"
    click_on "Próximo"
    find("label", text: "Romeira").click
    click_on "Próximo"
    find("label", text: "5 km").click
    click_on "Começar jornada"

    assert_text "Boa jornada, Nina!"
    assert_text "Primeiros Passos"

    click_on "Registrar caminhada", match: :first
    fill_in "Quantos km?", with: "8"
    click_on "Registrar caminhada"

    assert_text "Carimbo conquistado!"
    assert_text "Ponta das Areias"
    click_on "Continuar"

    assert_text "Primeiros Passos"
    assert_selector "[data-testid=phase]", text: %r{8\s*/ 90 km}
    assert_text "Missão cumprida!"
  end
end
