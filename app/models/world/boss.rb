class World::Boss
  KINDS = %w[ distance distance_with_load climb climb_with_load consecutive_days ].freeze

  attr_reader :name, :description, :kind, :km, :load_kg, :climb_m, :days, :phase

  def initialize(data, phase:)
    @name, @description, @kind = data.values_at("name", "description", "kind")
    @km = decimal(data["km"])
    @load_kg = decimal(data["load_kg"])
    @climb_m = decimal(data["climb_m"])
    @days = data["days"]
    @phase = phase

    validate
  end

  def defeated_on?(date, log:, since:)
    case kind
    when "distance" then log.walks_on(date).any? { it.km >= km } && date >= since
    when "distance_with_load" then log.walks_on(date).any? { it.km >= km && loaded?(it) } && date >= since
    when "climb" then date >= since && climbed(log.stair_sessions_on(date)) >= climb_m
    when "climb_with_load" then date >= since && climbed(log.stair_sessions_on(date).select { loaded?(it) }) >= climb_m
    when "consecutive_days" then consecutive_days_ending_on?(date, log: log, since: since)
    end
  end

  private
    def loaded?(record) = (record.load_kg || 0) >= load_kg

    def climbed(sessions) = sessions.sum(&:climb_m)

    def consecutive_days_ending_on?(date, log:, since:)
      window = (date - days + 1)..date

      window.first >= since &&
        window.all? { |day| log.walks_on(day).any? { loaded?(it) } } &&
        window.sum { |day| log.walks_on(day).sum(&:km) } >= km
    end

    def decimal(value) = value && BigDecimal(value.to_s)

    def validate
      raise World::Invalid, "chefe #{name}: tipo desconhecido #{kind}" if KINDS.exclude?(kind)

      missing = required_params.select { send(it).blank? }
      raise World::Invalid, "chefe #{name}: falta #{missing.join(", ")}" if missing.any?
      raise World::Invalid, "chefe #{name}: days precisa ser 2 ou mais" if kind == "consecutive_days" && days.to_i < 2
    end

    def required_params
      case kind
      when "distance" then %i[ km ]
      when "distance_with_load" then %i[ km load_kg ]
      when "climb" then %i[ climb_m ]
      when "climb_with_load" then %i[ climb_m load_kg ]
      when "consecutive_days" then %i[ km load_kg days ]
      end
    end
end
