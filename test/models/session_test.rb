require "test_helper"

class SessionTest < ActiveSupport::TestCase
  test "start! cria sessão com token" do
    session = users(:viajante).sessions.start!(user_agent: "teste", ip_address: "127.0.0.1")

    assert session.token.present?
    assert session.last_active_at
  end

  test "resume só atualiza depois de uma hora" do
    session = users(:viajante).sessions.start!(user_agent: "a", ip_address: "1.1.1.1")

    session.resume(user_agent: "b", ip_address: "2.2.2.2")
    assert_equal "a", session.reload.user_agent

    travel 2.hours do
      session.resume(user_agent: "b", ip_address: "2.2.2.2")
      assert_equal "b", session.reload.user_agent
    end
  end

  test "Current.session também define Current.user" do
    session = users(:viajante).sessions.start!(user_agent: "a", ip_address: "1.1.1.1")

    Current.session = session

    assert_equal users(:viajante), Current.user
  end
end
