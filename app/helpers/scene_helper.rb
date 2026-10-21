module SceneHelper
  PALETTES = [
    { sky: "#29435E", horizon: "#E2A05A", far: "#29435E", granite: "#1C2E44", ridge: "#132235" },
    { sky: "#1C2E44", horizon: "#E98A3C", far: "#29435E", granite: "#1C2E44", ridge: "#0E1A2A" },
    { sky: "#29435E", horizon: "#F2C46D", far: "#1C2E44", granite: "#132235", ridge: "#0E1A2A" },
    { sky: "#132235", horizon: "#5F9BB8", far: "#29435E", granite: "#1C2E44", ridge: "#132235" },
    { sky: "#1C2E44", horizon: "#CFE3EE", far: "#29435E", granite: "#132235", ridge: "#0E1A2A" },
    { sky: "#29435E", horizon: "#B98CFF", far: "#1C2E44", granite: "#1C2E44", ridge: "#132235" }
  ].freeze

  def scene_palette(phase)
    PALETTES[(phase.number - 1) % PALETTES.size]
  end

  def scene_label_anchor(x)
    if x < 60
      "start"
    elsif x > 220
      "end"
    else
      "middle"
    end
  end
end
