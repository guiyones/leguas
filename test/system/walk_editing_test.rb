require "application_system_test_case"

class WalkEditingTest < ApplicationSystemTestCase
  test "edita a observação de uma caminhada de 10 dias atrás" do
    user = users(:viajante)
    walk = user.walks.create!(km: 3, walked_on: Date.current)

    visit root_url
    fill_in "Email", with: user.email_address
    click_on "Receber código"
    assert_text "CÓDIGO"
    fill_in "Código de 6 dígitos", with: user.auth_tokens.order(:created_at).last.code
    click_on "Entrar"
    assert_selector "[data-testid='hud']"

    travel 10.days do
      visit edit_walk_url(walk)
      fill_in "Observação (opcional)", with: "Com chuva"
      click_on "Salvar"

      assert_text "Caminhada atualizada."
    end

    assert_equal "Com chuva", walk.reload.note
  end
end
