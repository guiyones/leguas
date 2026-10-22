class World
  class Invalid < StandardError; end

  ROOT = Rails.root.join("config/world")

  attr_reader :regions

  class << self
    attr_writer :current

    def current
      @current ||= load(ROOT)
    end

    def load(path)
      new(Dir[File.join(path, "*.yml")].sort.map { YAML.load_file(it) })
    end
  end

  def initialize(regions_data)
    @regions = build_regions(regions_data)
    validate_unique_keys
  end

  def phases = regions.flat_map(&:phases)
  def landmarks = phases.flat_map(&:landmarks)
  def milestones = @milestones ||= regions.flat_map(&:milestones)
  def total_km = regions.last.end_km

  def region(key) = regions.find { it.key == key }
  def phase(key) = phases.find { it.key == key }
  def landmark(key) = landmarks.find { it.key == key }
  def week(phase_key, number) = phase(phase_key)&.weeks&.find { it.number.to_s == number.to_s }

  private
    def build_regions(regions_data)
      start_km = BigDecimal(0)

      regions_data.map.with_index(1) do |data, number|
        Region.new(data, world: self, number: number, start_km: start_km).tap { start_km = it.end_km }
      end
    end

    def validate_unique_keys
      duplicated = (regions + phases + landmarks).map(&:key).tally.select { |_, count| count > 1 }.keys

      if duplicated.any?
        raise Invalid, "chaves repetidas no mundo: #{duplicated.join(", ")}"
      end
    end
end
