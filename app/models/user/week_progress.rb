# What a week's challenges got from the walks and stair sessions of the days spent in it.
class User::WeekProgress
  WALK_XP = 15
  LONG_WALK_XP = 30
  STAIRS_XP = 15
  COMPLETE_XP = 50

  def self.xp_per(challenge)
    case challenge.kind
    when :walks then WALK_XP
    when :long_walk then LONG_WALK_XP
    when :stairs then STAIRS_XP
    end
  end

  attr_reader :week

  def initialize(week, walks:, stair_sessions:)
    @week = week
    @walks = walks
    @stair_sessions = stair_sessions
  end

  def done(challenge)
    case challenge.kind
    when :walks then [ @walks.count { long_enough?(it, challenge) }, challenge.count ].min
    when :long_walk then @walks.any? { long_walk?(it, challenge) } ? 1 : 0
    when :stairs then [ @stair_sessions.size, challenge.count ].min
    end
  end

  def done?(challenge)
    done(challenge) >= (challenge.kind == :long_walk ? 1 : challenge.count)
  end

  def complete?
    week.challenges.any? && week.challenges.all? { done?(it) }
  end

  def xp
    week.challenges.sum { done(it) * self.class.xp_per(it) } + (complete? ? COMPLETE_XP : 0)
  end

  private
    def long_enough?(walk, challenge)
      walk.duration_s.present? && walk.duration_s >= challenge.min_minutes * 60
    end

    def long_walk?(walk, challenge)
      walk.km >= challenge.km && (challenge.load_kg.nil? || walk.load_kg.to_d >= challenge.load_kg)
    end
end
