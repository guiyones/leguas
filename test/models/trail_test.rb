require "test_helper"

class TrailTest < ActiveSupport::TestCase
  test "pontas e meio de uma reta" do
    trail = Trail.new([ [ 0, 0 ], [ 100, 0 ] ])
    assert_equal [ 0, 0 ], trail.point_at(0)
    assert_equal [ 50, 0 ], trail.point_at(0.5)
    assert_equal [ 100, 0 ], trail.point_at(1)
  end

  test "fração fora de 0..1 fica na ponta" do
    trail = Trail.new([ [ 0, 0 ], [ 100, 0 ] ])
    assert_equal [ 0, 0 ], trail.point_at(-1)
    assert_equal [ 100, 0 ], trail.point_at(2)
  end

  test "comprimento conta por segmento" do
    trail = Trail.new([ [ 0, 0 ], [ 30, 0 ], [ 30, 70 ] ])
    assert_equal [ 30, 20 ], trail.point_at(0.5)
  end

  test "path_d começa no ponto de from" do
    d = Trail.new([ [ 0, 0 ], [ 100, 0 ] ]).path_d(from: 0.25)
    assert_match(/\AM ?25(\.0)?[ ,]0/, d)
  end

  test "path_d termina no ponto de to" do
    d = Trail.new([ [ 0, 0 ], [ 100, 0 ] ]).path_d(to: 0.5)
    assert_match(/50\.0 0\.0\z/, d)
  end

  test "path_d é uma sequência válida de comandos M, Q e L" do
    d = Trail.new(Trail::PHASE).path_d
    assert_match(/\AM [\d. ]+( Q [\d. ]+)+ L [\d. ]+\z/, d)
  end

  test "trilhas prontas cabem no viewBox" do
    assert Trail::PHASE.all? { |x, y| x.between?(0, 280) && y.between?(0, 420) }
    assert Trail::WORLD.all? { |x, y| x.between?(0, 280) && y.between?(0, 600) }
  end
end
