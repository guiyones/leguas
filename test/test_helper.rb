ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
    def with_world(world)
      previous = World.current
      World.current = world
      yield
    ensure
      World.current = previous
    end

    def log_walks(user, *kms)
      kms.each_with_index { |km, days_ago| user.walks.create!(km: km, walked_on: Date.current - days_ago) }
    end

    private
      # Private so Minitest doesn't auto-discover this as a test case
      # (it grabs public instance methods matching /^test_/).
      def test_world
        World.load(Rails.root.join("test/world"))
      end
  end
end

require_relative "test_helpers/session_test_helper"

class ActionDispatch::IntegrationTest
  include SessionTestHelper
end
