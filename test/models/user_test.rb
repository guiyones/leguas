require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "normaliza o email" do
    user = User.create!(email_address: "  Andarilho@Leguas.TEST ")

    assert_equal "andarilho@leguas.test", user.email_address
  end

  test "email precisa ser válido e único" do
    assert_not User.new(email_address: "sem-arroba").valid?
    assert_not User.new(email_address: users(:viajante).email_address.upcase).valid?
  end

  test "degraus de 1 a 1000" do
    user = users(:novato)
    assert user.update(stair_steps: nil)
    assert user.update(stair_steps: 1)
    assert user.update(stair_steps: 1000)
    assert_not user.update(stair_steps: 0)
    assert_not user.update(stair_steps: 1001)
    assert_not user.update(stair_steps: 2.5)
  end
end
