require "test_helper"

class HealthTest < ActionDispatch::IntegrationTest
  test "o app sobe" do
    get rails_health_check_url
    assert_response :success
  end

  test "fuso e idioma" do
    assert_equal "Brasilia", Time.zone.name
    assert_equal :"pt-BR", I18n.default_locale
  end
end
