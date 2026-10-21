# Replays walks and stair sessions day by day. The position stops at the end of
# a phase whose boss is waiting; km walked past it stay banked until the boss falls.
class User::Journey
  LEAGUE_KM = 6
  XP_PER_KM = 10
  CLIMB_M_PER_XP = 5

  attr_reader :user, :world, :total_km, :position_km

  def initialize(user, world:)
    @user = user
    @world = world
    @log = user.training_log
    @boss_appeared_on = {}
    @boss_defeated_on = {}

    replay
  end

  def banked_km = total_km - position_km
  def climbed_m = @log.climbed_m
  def leagues = (total_km / LEAGUE_KM).floor

  def boss_appeared_on(phase) = @boss_appeared_on[phase.key]
  def boss_defeated_on(phase) = @boss_defeated_on[phase.key]

  def boss_status(phase)
    if phase_completed?(phase)
      :defeated
    elsif boss_appeared_on(phase)
      :waiting
    else
      :hidden
    end
  end

  def phase_completed?(phase)
    phase.boss? ? boss_defeated_on(phase).present? : phase.end_km <= position_km
  end

  def finished? = world.phases.all? { phase_completed?(it) }

  def current_phase
    world.phases.find { !phase_completed?(it) } || world.phases.last
  end

  def current_region = current_phase.region

  def km_in_phase
    (position_km - current_phase.start_km).clamp(0, current_phase.km)
  end

  def phase_progress
    km_in_phase / current_phase.km
  end

  def current_week
    current_phase.weeks.find { km_in_phase < it.end_km }
  end

  def next_milestone
    world.milestones.find { it.at_km > position_km }
  end

  def km_to_next
    if milestone = next_milestone
      milestone.at_km - position_km
    end
  end

  def reached_milestones
    @reached_milestones ||= world.milestones.select { reached?(it) }
  end

  def region_status(region)
    if region.phases.all? { phase_completed?(it) }
      :completed
    elsif region == current_region
      :current
    else
      :locked
    end
  end

  def phase_status(phase)
    if phase_completed?(phase)
      :completed
    elsif phase == current_phase
      boss_status(phase) == :waiting ? :boss : :current
    else
      :upcoming
    end
  end

  def landmark_reached?(landmark)
    landmark.world_km <= position_km
  end

  def xp
    @xp ||= (total_km * XP_PER_KM).floor + reached_milestones.sum(&:xp) +
      Mission::XP * user.missions.accomplished.count + (climbed_m / CLIMB_M_PER_XP).floor
  end

  def level
    User::Level.new(xp)
  end

  def achievement_keys
    reached_milestones.map(&:key) + level.reached_titles.map { "title:#{it.key}" }
  end

  private
    def replay
      @total_km = BigDecimal(0)
      gate = boss_phases.first

      @log.dates.each do |date|
        @total_km += @log.km_on(date)
        gate = advance(gate, on: date) if gate
      end

      @position_km = [ total_km, gate&.end_km || world.total_km ].min
    end

    # The gate is the boss phase holding the position. Each date is visited once,
    # so a boss that shows up on the day another one fell can only fall on a later day.
    def advance(gate, on:)
      @boss_appeared_on[gate.key] ||= on if total_km >= gate.end_km

      if boss_falls?(gate, on)
        @boss_defeated_on[gate.key] = @last_defeat_on = on

        boss_phases[boss_phases.index(gate) + 1].tap do |next_gate|
          @boss_appeared_on[next_gate.key] = on if next_gate && total_km >= next_gate.end_km
        end
      else
        gate
      end
    end

    def boss_falls?(phase, date)
      if appeared_on = boss_appeared_on(phase)
        phase.boss.defeated_on?(date, log: @log, since: [ appeared_on, @last_defeat_on&.next_day ].compact.max)
      end
    end

    def boss_phases
      @boss_phases ||= world.phases.select(&:boss?)
    end

    def reached?(milestone)
      case milestone.kind
      when :landmark then milestone.at_km <= position_km
      when :boss then boss_appeared_on(milestone.subject).present?
      when :phase then phase_completed?(milestone.subject)
      when :region then milestone.subject.phases.all? { phase_completed?(it) }
      end
    end
end
