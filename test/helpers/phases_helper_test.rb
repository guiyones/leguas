require "test_helper"

class PhasesHelperTest < ActionView::TestCase
  test "dica do dia gira pelas dicas da região" do
    region = test_world.region("alpha")

    assert_includes region.tips, tip_of_the_day(region)
  end

  test "região sem dicas não tem dica do dia" do
    assert_nil tip_of_the_day(test_world.region("beta"))
  end
end
