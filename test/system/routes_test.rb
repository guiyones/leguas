require "application_system_test_case"

class RoutesTest < ApplicationSystemTestCase
  test "escolher a rota preenche os km e dá pra trocar antes de salvar" do
    user = users(:viajante)
    user.routes.create!(name: "Volta do Guanabara", km: "3,55")

    visit root_url
    fill_in "Email", with: user.email_address
    click_on "Receber código"
    assert_text "CÓDIGO"
    fill_in "Código de 6 dígitos", with: user.auth_tokens.order(:created_at).last.code
    click_on "Entrar"
    assert_text "Começar jornada"

    visit new_walk_url
    select "Volta do Guanabara (3,55 km)", from: "Rota"
    assert_field "Quantos km?", with: "3.55"

    fill_in "Quantos km?", with: "4"
    click_on "Registrar caminhada"

    assert_no_field "Quantos km?"
    walk = user.walks.order(:id).last
    assert_equal 4, walk.km
    assert_equal "Volta do Guanabara", walk.route.name
  end
end
