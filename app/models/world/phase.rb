class World::Phase
  RARITIES = %w[ common rare legendary ].freeze

  attr_reader :key, :name, :inspired_by, :symbol, :rarity, :number, :region, :start_km, :km, :landmarks,
    :boss, :weeks, :focus, :note, :insignia_name, :bonus

  def initialize(data, region:, number:, start_km:)
    @key, @name, @inspired_by, @symbol = data.values_at("key", "name", "inspired_by", "symbol")
    @rarity = data.fetch("rarity", "common")
    @km = BigDecimal(data.fetch("km").to_s)
    @region = region
    @number = number
    @start_km = start_km
    @landmarks = Array(data["landmarks"]).map { World::Landmark.new(it, phase: self) }.sort_by(&:at_km)

    @focus, @note, @insignia_name = data.values_at("focus", "note", "insignia_name")
    @bonus = data["bonus"]
    @boss = data["boss"] && World::Boss.new(data["boss"], phase: self)
    @weeks = build_weeks(Array(data["weeks"]))

    validate
  end

  def end_km = start_km + km
  def boss? = boss.present?
  def rare? = rarity != "common"
  def legendary? = rarity == "legendary"
  def xp = rare? ? 250 : 100
  def insignia_size = rare? ? 20 : 16

  def milestones
    landmarks.map(&:milestone) + boss_milestones + [ World::Milestone.new(key: "phase:#{key}", kind: :phase, at_km: end_km, xp: xp, subject: self) ]
  end

  private
    def boss_milestones
      boss? ? [ World::Milestone.new(key: "boss:#{key}", kind: :boss, at_km: end_km, xp: 0, subject: self) ] : []
    end

    def build_weeks(weeks_data)
      week_start = BigDecimal(0)

      weeks_data.map.with_index(1) do |data, number|
        World::Week.new(data, number: number, start_km: week_start, light: number == weeks_data.size).tap { week_start = it.end_km }
      end
    end

    def validate
      if RARITIES.exclude?(rarity)
        raise World::Invalid, "fase #{key}: raridade desconhecida #{rarity}"
      end

      if landmarks.any? { !(it.at_km > 0 && it.at_km < km) }
        raise World::Invalid, "fase #{key}: marco precisa ficar entre 0 e #{km.to_s("F")} km (exclusivo)"
      end

      if weeks.any? && weeks.sum(&:km) != km
        raise World::Invalid, "fase #{key}: as semanas somam #{weeks.sum(&:km).to_s("F")} km, mas a fase tem #{km.to_s("F")} km"
      end
    end
end
