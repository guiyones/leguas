require "test_helper"

class TravelersControllerTest < ActionDispatch::IntegrationTest
  test "viajante sem nome é mandado pras boas-vindas" do
    sign_in :novato

    get root_url

    assert_redirected_to new_traveler_url
  end

  test "boas-vindas pergunta o nome" do
    sign_in :novato

    get new_traveler_url

    assert_response :success
    assert_select "h1", text: /Qual o seu nome, viajante\?/
    assert_select "input[name='user[name]'][autofocus]"
    assert_select "input[type=radio][name='user[avatar]']", 4
  end

  test "salvar leva pro início" do
    sign_in :novato

    post traveler_url, params: { user: { name: "Zé", avatar: "peregrino", daily_goal_km: "5" } }

    assert_redirected_to root_url
    assert_equal "Zé", users(:novato).reload.name
    assert_equal 5, users(:novato).daily_goal_km
  end

  test "sem nome volta com erro" do
    sign_in :novato

    post traveler_url, params: { user: { name: "", avatar: "peregrino", daily_goal_km: "5" } }

    assert_response :unprocessable_entity
  end

  test "quem já tem nome não vê as boas-vindas de novo" do
    sign_in :viajante

    get new_traveler_url

    assert_redirected_to root_url
  end

  test "sem nome ainda consegue sair" do
    sign_in :novato

    delete session_url

    assert_redirected_to new_session_url
  end
end
