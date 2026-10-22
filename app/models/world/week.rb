class World::Week
  attr_reader :number, :phase, :challenges, :km, :short_walks, :long_walk, :load, :stairs, :start_km

  def initialize(data, number:, start_km:, light:, phase:)
    @short_walks, @long_walk, @load, @stairs = data.values_at("short_walks", "long_walk", "load", "stairs")
    @km = BigDecimal(data.fetch("km").to_s)
    @number = number
    @start_km = start_km
    @light = light
    @phase = phase
    @challenges = build_challenges(data["challenges"] || {})
  end

  def end_km = start_km + km
  def light? = @light
  def stairs? = stairs.present? && stairs != "não"

  private
    def build_challenges(data)
      unknown = data.keys - World::Challenge::KINDS.map(&:to_s)
      raise World::Invalid, "semana #{number}: desafio desconhecido #{unknown.join(", ")}" if unknown.any?

      World::Challenge::KINDS.filter_map { |kind| World::Challenge.from(kind, data[kind.to_s]) if data[kind.to_s] }
    end
end
