class World::Challenge < Data.define(:kind, :count, :min_minutes, :km, :load_kg)
  KINDS = %i[ walks long_walk stairs ].freeze

  def self.from(kind, data)
    new(kind: kind.to_sym, count: data["count"], min_minutes: data["min_minutes"], km: data["km"], load_kg: data["load_kg"])
  end

  def label
    case kind
    when :walks then "#{count} caminhadas de #{min_minutes} min"
    when :long_walk then [ "Longão de #{km} km", ("com #{load_kg} kg" if load_kg) ].compact.join(" ")
    when :stairs then "#{count} #{count == 1 ? "sessão" : "sessões"} de escada"
    end
  end

  def max_xp = User::WeekProgress.xp_per(self) * (kind == :long_walk ? 1 : count)
end
