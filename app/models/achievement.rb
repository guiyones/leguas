Achievement = Data.define(:key, :kind, :subject) do
  def self.find(key, world: World.current)
    kind, subject_key = key.to_s.split(":", 2)

    if subject = subject_for(kind, subject_key, world)
      new(key: key, kind: kind, subject: subject)
    end
  end

  def self.subject_for(kind, subject_key, world)
    case kind
    when "landmark" then world.landmark(subject_key)
    when "boss" then world.phase(subject_key)
    when "phase" then world.phase(subject_key)
    when "region" then world.region(subject_key)
    when "title" then User::Level.title(subject_key)
    when "week" then world.week(*subject_key.to_s.split(":", 2).values_at(0, 1))
    end
  end
end
