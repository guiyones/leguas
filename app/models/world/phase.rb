class World::Phase
  RARITIES = %w[ common rare legendary ].freeze

  attr_reader :key, :name, :inspired_by, :symbol, :rarity, :number, :region, :start_km, :km, :landmarks

  def initialize(data, region:, number:, start_km:)
    @key, @name, @inspired_by, @symbol = data.values_at("key", "name", "inspired_by", "symbol")
    @rarity = data.fetch("rarity", "common")
    @km = BigDecimal(data.fetch("km").to_s)
    @region = region
    @number = number
    @start_km = start_km
    @landmarks = Array(data["landmarks"]).map { World::Landmark.new(it, phase: self) }.sort_by(&:at_km)

    validate
  end

  def end_km = start_km + km
  def boss? = rarity != "common"
  def legendary? = rarity == "legendary"
  def xp = boss? ? 250 : 100
  def insignia_size = boss? ? 20 : 16

  def milestones
    landmarks.map(&:milestone) + [ World::Milestone.new(key: "phase:#{key}", kind: :phase, at_km: end_km, xp: xp, subject: self) ]
  end

  private
    def validate
      if RARITIES.exclude?(rarity)
        raise World::Invalid, "fase #{key}: raridade desconhecida #{rarity}"
      end

      if landmarks.any? { !(it.at_km > 0 && it.at_km < km) }
        raise World::Invalid, "fase #{key}: marco precisa ficar entre 0 e #{km.to_s("F")} km (exclusivo)"
      end
    end
end
