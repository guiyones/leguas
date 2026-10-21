class World::Week
  attr_reader :number, :km, :short_walks, :long_walk, :load, :stairs, :start_km

  def initialize(data, number:, start_km:, light:)
    @short_walks, @long_walk, @load, @stairs = data.values_at("short_walks", "long_walk", "load", "stairs")
    @km = BigDecimal(data.fetch("km").to_s)
    @number = number
    @start_km = start_km
    @light = light
  end

  def end_km = start_km + km
  def light? = @light
end
