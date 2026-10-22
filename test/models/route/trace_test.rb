require "test_helper"

class Route::TraceTest < ActiveSupport::TestCase
  test "normaliza preservando a proporção e centralizando o lado menor" do
    points = [ [ 0, 0 ], [ 100, 0 ], [ 100, 50 ], [ 0, 50 ] ]

    assert_equal [ [ 0, 0.25 ], [ 1, 0.25 ], [ 1, 0.75 ], [ 0, 0.75 ] ], Route::Trace.normalize(points)
  end

  test "normalizar duas vezes dá o mesmo resultado" do
    once = Route::Trace.normalize([ [ -46.6, -23.5 ], [ -46.5, -23.6 ], [ -46.62, -23.58 ] ])

    assert_equal once, Route::Trace.normalize(once)
  end

  test "menos de 2 pontos vira lista vazia" do
    assert_equal [], Route::Trace.normalize([ [ 1, 1 ] ])
    assert_equal [], Route::Trace.normalize([])
  end

  test "pontos todos iguais ficam no centro" do
    assert_equal [ [ 0.5, 0.5 ], [ 0.5, 0.5 ] ], Route::Trace.normalize([ [ 3, 3 ], [ 3, 3 ] ])
  end

  test "valid? aceita de 2 a 300 pares numéricos" do
    assert Route::Trace.valid?([ [ 0, 0 ], [ 1, 1 ] ])
    assert Route::Trace.valid?(Array.new(300) { |i| [ i, i ] })
    assert_not Route::Trace.valid?(Array.new(301) { |i| [ i, i ] })
    assert_not Route::Trace.valid?([ [ 0, 0 ] ])
    assert_not Route::Trace.valid?([ [ "a", 1 ], [ 1, 1 ] ])
    assert_not Route::Trace.valid?([ [ 0, 0, 0 ], [ 1, 1 ] ])
    assert_not Route::Trace.valid?({ "a" => 1 })
    assert_not Route::Trace.valid?(nil)
  end
end
