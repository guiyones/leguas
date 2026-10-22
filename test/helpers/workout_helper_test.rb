require "test_helper"

class WorkoutHelperTest < ActionView::TestCase
  test "ritmo por km" do
    assert_equal "10'57\"/km", pace(3.55, 2331)
  end

  test "velocidade com vírgula" do
    assert_equal "5,5 km/h", speed(3.55, 2331)
  end

  test "sem tempo não há ritmo nem velocidade" do
    assert_nil pace(3.55, nil)
    assert_nil speed(3.55, nil)
  end

  test "texto do tempo" do
    assert_equal "38:51", duration_text(2331)
    assert_equal "1:05:20", duration_text(3920)
  end
end
