require "test_helper"

class StairSessionsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in :viajante }

  test "formulário com atalhos e mochila" do
    get new_stair_session_url

    assert_response :success
    assert_select "input[name='stair_session[climbs]']"
    assert_select "input[name='stair_session[load_kg]']"
    assert_select "input[name='user[stair_steps]']", 0
  end

  test "registrar escada dá XP e volta pro início" do
    assert_difference -> { users(:viajante).stair_sessions.count }, 1 do
      post stair_sessions_url, params: { stair_session: { climbs: "12", climbed_on: Date.current.iso8601 } }
    end

    assert_redirected_to root_url
    assert_equal "+20 XP", flash[:notice]   # 12 * 50 * 0,17 = 102 m
  end

  test "sem degraus no perfil o form pede os degraus" do
    users(:viajante).update!(stair_steps: nil)

    get new_stair_session_url
    assert_select "input[name='user[stair_steps]']"

    assert_difference -> { users(:viajante).stair_sessions.count }, 1 do
      post stair_sessions_url, params: { user: { stair_steps: "40" },
                                         stair_session: { climbs: "5", climbed_on: Date.current.iso8601 } }
    end
    assert_equal 40, users(:viajante).reload.stair_steps
  end

  test "degraus inválidos re-renderizam com 422" do
    users(:viajante).update!(stair_steps: nil)

    post stair_sessions_url, params: { user: { stair_steps: "5000" },
                                       stair_session: { climbs: "5", climbed_on: Date.current.iso8601 } }

    assert_response :unprocessable_entity
    assert_select ".field-error"
    assert_nil users(:viajante).reload.stair_steps
    assert_equal 0, users(:viajante).stair_sessions.count
  end

  test "parâmetro user solto não quebra o registro" do
    assert_difference -> { users(:viajante).stair_sessions.count }, 1 do
      post stair_sessions_url, params: { user: "x", stair_session: { climbs: "5", climbed_on: Date.current.iso8601 } }
    end

    assert_redirected_to root_url
  end

  test "editar e excluir" do
    session = users(:viajante).stair_sessions.create!(climbs: 3, climbed_on: Date.current)

    get edit_stair_session_url(session)
    assert_response :success

    patch stair_session_url(session), params: { stair_session: { climbs: "4", load_kg: "5,5" } }
    assert_redirected_to walks_url
    assert_equal 4, session.reload.climbs
    assert_equal 5.5, session.load_kg

    delete stair_session_url(session)
    assert_redirected_to walks_url
    assert_not StairSession.exists?(session.id)
  end

  test "subidas inválidas re-renderizam com 422" do
    post stair_sessions_url, params: { stair_session: { climbs: "0", climbed_on: Date.current.iso8601 } }

    assert_response :unprocessable_entity
    assert_select ".field-error"
  end

  test "não mexe na escada de outro viajante" do
    other = users(:novato).tap { it.update!(stair_steps: 10) }.stair_sessions.create!(climbs: 1, climbed_on: Date.current)

    patch stair_session_url(other), params: { stair_session: { climbs: "9" } }

    assert_response :not_found
  end

  test "não abre nem exclui a escada de outro viajante" do
    other = users(:novato).tap { it.update!(stair_steps: 10) }.stair_sessions.create!(climbs: 1, climbed_on: Date.current)

    get edit_stair_session_url(other)
    assert_response :not_found

    assert_no_difference -> { StairSession.count } do
      delete stair_session_url(other)
    end
    assert_response :not_found
  end
end
