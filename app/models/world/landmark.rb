class World::Landmark
  XP = 25

  attr_reader :key, :name, :story, :at_km, :phase

  def initialize(data, phase:)
    @key, @name, @story = data.values_at("key", "name", "story")
    @at_km = BigDecimal(data.fetch("at_km").to_s)
    @phase = phase
  end

  def world_km = phase.start_km + at_km
  def xp = XP

  def milestone
    World::Milestone.new(key: "landmark:#{key}", kind: :landmark, at_km: world_km, xp: xp, subject: self)
  end
end
