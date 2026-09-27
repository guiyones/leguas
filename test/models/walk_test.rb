require "test_helper"

class WalkTest < ActiveSupport::TestCase
  setup { @user = users(:viajante) }

  test "km precisa ser maior que zero" do
    assert_not @user.walks.new(km: 0, walked_on: Date.current).valid?
    assert_not @user.walks.new(km: -2, walked_on: Date.current).valid?
    assert @user.walks.new(km: 0.5, walked_on: Date.current).valid?
  end

  test "aceita vírgula decimal do teclado brasileiro" do
    walk = @user.walks.create!(km: "3,5", walked_on: Date.current)

    assert_equal BigDecimal("3.5"), walk.reload.km
  end

  test "data vai de hoje até 7 dias atrás" do
    assert @user.walks.new(km: 1, walked_on: Date.current - 7).valid?
    assert_not @user.walks.new(km: 1, walked_on: Date.current - 8).valid?
    assert_not @user.walks.new(km: 1, walked_on: Date.current + 1).valid?
  end

  test "às 23h30 de Brasília ainda é hoje" do
    travel_to Time.zone.local(2026, 9, 26, 23, 30) do
      walk = @user.walks.create!(km: 2, walked_on: Date.current)

      assert_equal Date.new(2026, 9, 26), walk.walked_on
      assert @user.walks.new(km: 1, walked_on: Date.new(2026, 9, 19)).valid?
    end
  end

  test "soma do dia não passa de 100 km" do
    @user.walks.create!(km: 90, walked_on: Date.current)

    walk = @user.walks.new(km: 11, walked_on: Date.current)

    assert_not walk.valid?
    assert_includes walk.errors[:km].join, "Essa distância parece exagerada, viajante."
    assert @user.walks.new(km: 10, walked_on: Date.current).valid?
  end

  test "editar a própria caminhada não conta ela duas vezes no limite" do
    walk = @user.walks.create!(km: 60, walked_on: Date.current)

    assert walk.update(km: 70)
  end

  test "mudar a data pra um dia cheio respeita o limite" do
    @user.walks.create!(km: 90, walked_on: Date.current)
    walk = @user.walks.create!(km: 20, walked_on: Date.current - 1)

    assert_not walk.update(walked_on: Date.current)
  end

  test "caminhada antiga pode ter a observação editada" do
    walk = @user.walks.create!(km: 5, walked_on: Date.current)

    travel 10.days do
      assert walk.update(note: "Com chuva")
    end
  end

  test "caminhada antiga não pode ir pra outra data fora da janela" do
    walk = @user.walks.create!(km: 5, walked_on: Date.current)

    travel 10.days do
      assert_not walk.update(walked_on: Date.current - 9)
    end
  end

  test "salvar cria a missão do dia com a meta atual" do
    assert_difference -> { @user.missions.count }, 1 do
      @user.walks.create!(km: 1, walked_on: Date.current)
    end

    assert_equal 3, @user.missions.find_by(date: Date.current).goal_km
  end
end
