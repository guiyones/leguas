require "test_helper"

class AuthTokenMailerTest < ActionMailer::TestCase
  test "envia o código" do
    token = users(:viajante).auth_tokens.create!(expires_at: AuthToken::EXPIRATION.from_now)

    mail = AuthTokenMailer.otp(token)

    assert_equal [ "viajante@leguas.test" ], mail.to
    assert_equal "Seu código pra entrar no Léguas", mail.subject
    assert_includes mail.body.to_s, token.code
  end
end
