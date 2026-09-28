require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 390, 844 ] do |options|
    options.binary = ENV.fetch("CHROME_BIN", "/usr/bin/chromium")
  end
end
