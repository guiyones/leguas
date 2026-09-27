require "test_helper"

class AuthTokenTest < ActiveSupport::TestCase
  setup { @user = users(:viajante) }

  test "gera um código de 6 dígitos ao criar" do
    token = @user.auth_tokens.create!(expires_at: AuthToken::EXPIRATION.from_now)

    assert_match(/\A\d{6}\z/, token.code)
  end

  test "lookup encontra token válido pelo email e código" do
    token = @user.auth_tokens.create!(expires_at: AuthToken::EXPIRATION.from_now)

    assert_equal token, AuthToken.lookup(email_address: "VIAJANTE@leguas.test", code: token.code)
  end

  test "lookup ignora token expirado, usado ou código errado" do
    expired = @user.auth_tokens.create!(expires_at: 1.minute.ago)
    used = @user.auth_tokens.create!(expires_at: 10.minutes.from_now, used_at: Time.current)

    assert_nil AuthToken.lookup(email_address: @user.email_address, code: expired.code)
    assert_nil AuthToken.lookup(email_address: @user.email_address, code: used.code)
    assert_nil AuthToken.lookup(email_address: @user.email_address, code: "000000")
    assert_nil AuthToken.lookup(email_address: nil, code: nil)
  end

  test "use! marca como usado e apaga os outros tokens do usuário" do
    token = @user.auth_tokens.create!(expires_at: 10.minutes.from_now)
    other = @user.auth_tokens.create!(expires_at: 10.minutes.from_now)

    token.use!

    assert token.reload.used_at
    assert_not AuthToken.exists?(other.id)
  end
end
