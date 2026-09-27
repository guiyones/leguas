class User::Level
  Title = Data.define(:key, :name, :from_level)

  TITLES = [
    Title.new(key: "caminhante", name: "Caminhante", from_level: 1),
    Title.new(key: "andarilho", name: "Andarilho", from_level: 5),
    Title.new(key: "aventureiro", name: "Aventureiro", from_level: 10),
    Title.new(key: "peregrino", name: "Peregrino", from_level: 15),
    Title.new(key: "desbravador", name: "Desbravador", from_level: 20),
    Title.new(key: "lenda", name: "Lenda das Léguas", from_level: 25)
  ].freeze

  attr_reader :xp

  def self.xp_for(number)
    40 * (number - 1)**2
  end

  def self.title(key)
    TITLES.find { it.key == key }
  end

  def initialize(xp)
    @xp = xp.to_i
  end

  def number
    Integer.sqrt(xp / 40) + 1
  end

  def title
    TITLES.reverse.find { it.from_level <= number }
  end

  def reached_titles
    TITLES.select { it.from_level <= number }.drop(1)
  end

  def progress
    floor = self.class.xp_for(number)
    (xp - floor).fdiv(self.class.xp_for(number + 1) - floor)
  end

  def xp_to_next
    self.class.xp_for(number + 1) - xp
  end
end
