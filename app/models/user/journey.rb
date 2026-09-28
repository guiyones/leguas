class User::Journey
  LEAGUE_KM = 6
  XP_PER_KM = 10

  attr_reader :user, :world, :total_km

  def initialize(user, world:)
    @user = user
    @world = world
    @total_km = user.walks.sum(:km)
  end

  def leagues = (total_km / LEAGUE_KM).floor
  def finished? = total_km >= world.total_km

  def current_phase
    world.phases.find { total_km < it.end_km } || world.phases.last
  end

  def current_region = current_phase.region

  def km_in_phase
    [ total_km - current_phase.start_km, current_phase.km ].min
  end

  def phase_progress
    km_in_phase / current_phase.km
  end

  def next_milestone
    world.milestones.find { it.at_km > total_km }
  end

  def km_to_next
    if milestone = next_milestone
      milestone.at_km - total_km
    end
  end

  def reached_milestones
    world.milestones.select { it.at_km <= total_km }
  end

  def completed_phases
    world.phases.select { it.end_km <= total_km }
  end

  def region_status(region)
    if region.end_km <= total_km
      :completed
    elsif region == current_region
      :current
    else
      :locked
    end
  end

  def phase_status(phase)
    if phase.end_km <= total_km
      :completed
    elsif phase == current_phase
      :current
    else
      :upcoming
    end
  end

  def landmark_reached?(landmark)
    landmark.world_km <= total_km
  end

  def xp
    @xp ||= (total_km * XP_PER_KM).floor + reached_milestones.sum(&:xp) + Mission::XP * user.missions.accomplished.count
  end

  def level
    User::Level.new(xp)
  end

  def achievement_keys
    reached_milestones.map(&:key) + level.reached_titles.map { "title:#{it.key}" }
  end
end
