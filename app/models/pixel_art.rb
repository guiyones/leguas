class PixelArt
  class Invalid < StandardError; end

  ROOT = Rails.root.join("app/pixel_art")
  TRANSPARENT = "."

  attr_reader :path, :rows

  def self.palette(root: ROOT)
    @palettes ||= {}
    @palettes[root] ||= YAML.load_file(root.join("palette.yml"))
  end

  def self.find(kind, key, root: ROOT)
    path = root.join(kind.to_s, "#{key}.txt")

    if path.exist?
      new(path, palette: palette(root: root))
    else
      raise Invalid, "#{path}: arquivo não existe"
    end
  end

  def initialize(path, palette:)
    @path = path
    @palette = palette
    @rows = File.readlines(path, chomp: true).reject(&:blank?)
  end

  def width = rows.first.to_s.length
  def height = rows.size

  def validate(size:)
    unless height == size && rows.all? { it.length == size }
      raise Invalid, "#{path}: esperado #{size}x#{size}"
    end

    unknown = rows.join.chars.uniq - [ TRANSPARENT ] - @palette.keys
    if unknown.any?
      raise Invalid, "#{path}: cores fora da paleta: #{unknown.join(", ")}"
    end
  end

  def color(char) = @palette.fetch(char)

  def runs
    rows.each_with_index.flat_map { |row, y| runs_in(row, y) }
  end

  private
    def runs_in(row, y)
      x = 0

      row.chars.chunk_while { |a, b| a == b }.filter_map do |chunk|
        run = [ x, y, chunk.size, chunk.first ]
        x += chunk.size
        run unless chunk.first == TRANSPARENT
      end
    end
end
