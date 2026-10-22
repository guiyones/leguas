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

  test "data mínima do formulário: nova caminhada usa a janela de 7 dias" do
    walk = @user.walks.new(walked_on: Date.current)

    assert_equal Date.current - Walk::RETROACTIVE_DAYS, walk.walked_on_min
  end

  test "data mínima do formulário: caminhada antiga permite manter a própria data" do
    walk = @user.walks.create!(km: 3, walked_on: Date.current)

    travel 10.days do
      assert_equal walk.walked_on, walk.walked_on_min
    end
  end

  test "salvar cria a missão do dia com a meta atual" do
    assert_difference -> { @user.missions.count }, 1 do
      @user.walks.create!(km: 1, walked_on: Date.current)
    end

    assert_equal 3, @user.missions.find_by(date: Date.current).goal_km
  end

  test "mochila opcional, com vírgula, até 40 kg" do
    walk = @user.walks.create!(km: 2, walked_on: Date.current, load_kg: "7,5")
    assert_equal BigDecimal("7.5"), walk.reload.load_kg
    assert @user.walks.new(km: 2, walked_on: Date.current, load_kg: nil).valid?
    assert_not @user.walks.new(km: 2, walked_on: Date.current, load_kg: 0).valid?
    assert_not @user.walks.new(km: 2, walked_on: Date.current, load_kg: 41).valid?
  end

  test "tempo aceita m, m:ss e h:mm:ss" do
    { "38:51" => 2331, "1:05:20" => 3920, "45" => 2700 }.each do |text, seconds|
      assert_equal seconds, @user.walks.new(km: 1, walked_on: Date.current, duration: text).duration_s
    end
    assert_nil @user.walks.new(km: 1, walked_on: Date.current, duration: "").duration_s
  end

  test "tempo inválido não passa" do
    [ "abc", "10:75" ].each do |text|
      walk = @user.walks.new(km: 1, walked_on: Date.current, duration: text)

      assert_not walk.valid?
      assert_includes walk.errors[:duration], "não parece um tempo, use 38:51"
    end
  end

  test "tempo é lido de volta como texto" do
    assert_equal "38:51", @user.walks.new(duration_s: 2331).duration
    assert_equal "1:05:20", @user.walks.new(duration_s: 3920).duration
    assert_nil @user.walks.new.duration
  end

  test "passos aceitam ponto de milhar" do
    assert_equal 4507, @user.walks.new(steps: "4.507").steps
  end

  test "subida não pode ser negativa" do
    assert_not @user.walks.new(km: 1, walked_on: Date.current, elevation_gain_m: -1).valid?
    assert @user.walks.new(km: 1, walked_on: Date.current, elevation_gain_m: 32).valid?
  end

  test "tempo zero ou acima de 24h é inválido" do
    [ "0", "0:00", "0:00:00", "99999999", "24:00:01" ].each do |text|
      walk = @user.walks.new(km: 1, walked_on: Date.current, duration: text)

      assert_not walk.valid?, text
      assert_nil walk.duration_s
    end
    assert @user.walks.new(km: 1, walked_on: Date.current, duration: "24:00:00").valid?
  end

  test "valores enormes dão erro de validação, não exceção" do
    walk = @user.walks.new(km: 1, walked_on: Date.current, steps: "99999999999", elevation_gain_m: 99999999999)

    assert_not walk.valid?
    assert walk.errors[:steps].any?
    assert walk.errors[:elevation_gain_m].any?
  end

  test "passos precisam ser positivos e até 200.000" do
    assert_not @user.walks.new(km: 1, walked_on: Date.current, steps: 0).valid?
    assert_not @user.walks.new(km: 1, walked_on: Date.current, steps: 200_001).valid?
    assert @user.walks.new(km: 1, walked_on: Date.current, steps: "200.000").valid?
  end

  test "subida acima de 10.000 m é inválida" do
    assert_not @user.walks.new(km: 1, walked_on: Date.current, elevation_gain_m: 10_001).valid?
  end
end
