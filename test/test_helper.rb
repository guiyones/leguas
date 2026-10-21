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

    def walk_on(user, days_ago, km, load_kg: nil)
      user.walks.new(km: km, walked_on: Date.current - days_ago, load_kg: load_kg).tap { it.save!(validate: false) }
    end

    def climb_on(user, days_ago, climbs, load_kg: nil)
      user.stair_sessions.new(climbs: climbs, climbed_on: Date.current - days_ago, load_kg: load_kg).tap { it.save!(validate: false) }
    end

    # Caminhadas de no máximo 10 km, uma por dia, terminando em until_days_ago.
    def walk_steady(user, total_km, until_days_ago: 1)
      remaining = total_km.to_d
      days_ago = until_days_ago
      walks = []
      while remaining > 0
        walks << [ days_ago, [ remaining, 10 ].min ]
        remaining -= walks.last.last
        days_ago += 1
      end
      walks.each { |days, km| walk_on(user, days, km) }
      nil
    end

    # Percorre o mundo inteiro: caminhadas de até 10 km até cada chefe aparecer e,
    # no dia seguinte, o feito que derruba o chefe. Termina hoje.
    def travel_whole_world(user, world: World.current)
      user.update!(stair_steps: 100)   # 17 m por subida
      days = []
      total = 0

      world.phases.each do |phase|
        while total < phase.end_km
          km = [ phase.end_km - total, 10 ].min
          days << [ :walk, km, nil ]
          total += km
        end

        boss = phase.boss
        case boss.kind
        when "distance", "distance_with_load"
          days << [ :walk, boss.km, boss.load_kg ]
          total += boss.km
        when "climb", "climb_with_load"
          days << [ :climb, (boss.climb_m / 17).ceil, boss.load_kg ]
        when "consecutive_days"
          boss.days.times do
            days << [ :walk, (boss.km / boss.days).ceil, boss.load_kg ]
            total += (boss.km / boss.days).ceil
          end
        end
      end

      days.each_with_index do |(kind, amount, load_kg), index|
        days_ago = days.size - 1 - index
        kind == :walk ? walk_on(user, days_ago, amount, load_kg: load_kg) : climb_on(user, days_ago, amount, load_kg: load_kg)
      end
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
