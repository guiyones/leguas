require "test_helper"

class StairSessionTest < ActiveSupport::TestCase
  test "desnível usa os degraus do perfil" do
    session = users(:viajante).stair_sessions.create!(climbs: 10, climbed_on: Date.current)
    assert_equal BigDecimal("85"), session.climb_m           # 10 × 50 × 0,17
  end

  test "sem degraus no perfil o desnível é zero" do
    user = users(:viajante)
    session = climb_on user, 1, 10
    user.stair_steps = nil
    assert_equal 0, session.climb_m
  end

  test "sem degraus no perfil não registra" do
    session = users(:novato).stair_sessions.new(climbs: 3, climbed_on: Date.current)
    assert_not session.valid?
    assert_equal [ "Informe os degraus da sua escada no perfil antes de registrar subidas." ], session.errors.full_messages
  end

  test "subidas inteiras e maiores que zero, até 500 por dia" do
    user = users(:viajante)
    assert_not user.stair_sessions.new(climbs: 0, climbed_on: Date.current).valid?
    user.stair_sessions.create!(climbs: 450, climbed_on: Date.current)
    assert_not user.stair_sessions.new(climbs: 51, climbed_on: Date.current).valid?
  end

  test "data vai de hoje até 7 dias atrás" do
    user = users(:viajante)
    assert user.stair_sessions.new(climbs: 1, climbed_on: Date.current - 7).valid?
    assert_not user.stair_sessions.new(climbs: 1, climbed_on: Date.current - 8).valid?
  end

  test "mochila opcional até 40 kg" do
    user = users(:viajante)
    assert user.stair_sessions.new(climbs: 1, climbed_on: Date.current, load_kg: nil).valid?
    assert_not user.stair_sessions.new(climbs: 1, climbed_on: Date.current, load_kg: 41).valid?
  end

  test "mudar os degraus esquece celebrações que deixaram de valer" do
    user = users(:viajante)
    user.celebrations.create!(key: "inexistente")
    user.update!(stair_steps: 60)
    assert_not user.celebrations.exists?(key: "inexistente")
  end
end
