require "test_helper"

class ProgressHelperTest < ActionView::TestCase
  test "barra contínua com valor e cor" do
    bar = Nokogiri::HTML(progress_bar(0.39)).at("[role=progressbar]")

    assert_equal "39", bar["aria-valuenow"]
    assert_includes bar["class"], "progress--gold"
    assert_includes Nokogiri::HTML(progress_bar(0.5, color: :lake)).at(".progress")["class"], "progress--lake"
  end

  test "limita entre 0 e 1" do
    assert_includes progress_bar(1.7), 'aria-valuenow="100"'
    assert_includes progress_bar(-1), 'aria-valuenow="0"'
  end
end
