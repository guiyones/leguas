module SceneHelper
  PHASE_TRAIL = Trail.new(Trail::PHASE)

  # O viajante para antes do ponto do chefe, para não ficar em cima dele.
  TRAVELER_MAX = 0.94

  # Nomes dos tokens --color-* de application.css, uma paleta por fase.
  PALETTES = [
    { sky: "sky", horizon: "horizon", far: "sky", granite: "ridge", ridge: "ridge-2" },
    { sky: "ridge", horizon: "ember", far: "sky", granite: "ridge", ridge: "ridge-3" },
    { sky: "sky", horizon: "gold", far: "ridge", granite: "ridge-2", ridge: "ridge-3" },
    { sky: "ridge-2", horizon: "lake", far: "sky", granite: "ridge", ridge: "ridge-2" },
    { sky: "ridge", horizon: "ice", far: "sky", granite: "ridge-2", ridge: "ridge-3" },
    { sky: "sky", horizon: "legend", far: "ridge", granite: "ridge", ridge: "ridge-2" }
  ].freeze

  def scene_trail = PHASE_TRAIL

  def scene_traveler_point(progress)
    PHASE_TRAIL.point_at([ progress, TRAVELER_MAX ].min)
  end

  def scene_boss_point
    PHASE_TRAIL.point_at(1)
  end

  def scene_palette(phase)
    PALETTES[(phase.number - 1) % PALETTES.size]
  end

  def scene_palette_style(phase)
    scene_palette(phase).map { |part, token| "--scene-#{part}: var(--color-#{token})" }.join("; ")
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
