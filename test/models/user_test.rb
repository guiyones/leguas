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
end
