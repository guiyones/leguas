require "test_helper"

class TrophiesControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in :viajante }

  test "encaixes refletem as fases" do
    vencer_fase_1

    get trophies_url

    assert_response :success
    assert_select "[data-slot=primeiros_passos][data-state=filled]"
    assert_select "[data-slot=carga_leve][data-state=current]"
    World.current.phases.drop(2).each do |phase|
      assert_select "[data-slot=#{phase.key}][data-state=empty]"
    end
  end

  test "insígnia com data do chefe derrotado" do
    vencer_fase_1
    date = users(:viajante).journey.boss_defeated_on(World.current.phases.first)

    get trophies_url

    assert_select "*", text: "Pegada do Viajante"
    assert_select "*", text: "Fase 1 vencida · #{I18n.l(date, format: :short)}"
  end

  test "certificado desabilitado antes do fim" do
    get trophies_url

    assert_select "[disabled]", text: /ao completar a trilha/
    assert_select "[data-testid=certificate]", count: 0
  end

  test "certificado no fim" do
    user = users(:viajante)
    travel_whole_world user
    journey = user.journey

    get trophies_url

    assert_select "[data-testid=certificate]" do
      assert_select "*", text: /#{user.name}/
      assert_select "*", text: /A Trilha do Vento Austral/
      assert_select "*", text: /#{ActiveSupport::NumberHelper.number_to_rounded(journey.total_km, precision: 1, strip_insignificant_zeros: true)} km/
      assert_select "*", text: /#{I18n.l(user.training_log.dates.first, format: :short)}/
      assert_select "*", text: /#{I18n.l(journey.boss_defeated_on(World.current.phases.last), format: :short)}/
    end
  end

  test "menu leva aos troféus" do
    get root_url

    assert_select "a[href=?]", trophies_path, text: "Troféus"
  end

  private
    def vencer_fase_1
      walk_steady users(:viajante), 90, until_days_ago: 2
      walk_on users(:viajante), 1, 12
    end
end
