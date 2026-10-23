require "application_system_test_case"

class MapTest < ApplicationSystemTestCase
  test "tocar na bolinha da fase abre a janela com os detalhes e fecha no X" do
    user = users(:viajante)
    sign_in_as user
    visit map_url

    find("[data-world-phase=a_subida]").click

    within "dialog#fase-a_subida[open]" do
      assert_text "A Subida"
      assert_text "Trecho 1"
      click_on "Fechar"
    end
    assert_no_selector "dialog[open]"
  end

  private
    def sign_in_as(user)
      visit root_url
      fill_in "Email", with: user.email_address
      click_on "Receber código"
      assert_text "CÓDIGO"
      fill_in "Código de 6 dígitos", with: user.auth_tokens.order(:created_at).last.code
      click_on "Entrar"
      assert_text "Começar jornada"
    end
end
