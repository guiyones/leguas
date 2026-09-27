class World::Region
  XP = 500

  attr_reader :key, :name, :inspired_by, :trophy_name, :number, :phases, :start_km

  def initialize(data, world:, number:, start_km:)
    @world = world
    @key, @name, @inspired_by, @trophy_name = data.values_at("key", "name", "inspired_by", "trophy_name")
    @number = number
    @start_km = start_km
    @phases = build_phases(data.fetch("phases"))
  end

  def end_km = phases.last.end_km
  def km = end_km - start_km
  def next = @world.regions[number]

  def milestones
    phases.flat_map(&:milestones) + [ World::Milestone.new(key: "region:#{key}", kind: :region, at_km: end_km, xp: XP, subject: self) ]
  end

  def xp
    (km * 10).floor + milestones.sum(&:xp)
  end

  private
    def build_phases(phases_data)
      phase_start = start_km

      phases_data.map.with_index(1) do |data, number|
        World::Phase.new(data, region: self, number: number, start_km: phase_start).tap { phase_start = it.end_km }
      end
    end
end
