module MapsHelper
  # O mapa em pé é o do celular; o deitado, o do computador.
  WORLD_TRAILS = { tall: Trail.new(Trail::WORLD), wide: Trail.new(Trail::WORLD_WIDE) }.freeze
  WORLD_MIDDLE = 140
  LABEL_GAP = 18
  LABEL_BELOW = 30

  def world_trail(layout = :tall) = WORLD_TRAILS.fetch(layout)

  def world_nodes(region, layout = :tall)
    last = [ region.phases.size - 1, 1 ].max
    region.phases.each_with_index.map { |phase, index| [ phase, world_trail(layout).point_at(index / last.to_f).map { it.round(1) } ] }
  end

  def world_walked_fraction(region, journey)
    if journey.region_status(region) == :completed
      1
    elsif index = region.phases.index(journey.current_phase)
      index / [ region.phases.size - 1, 1 ].max.to_f
    else
      0
    end
  end

  # No mapa em pé o rótulo fica do lado livre do nó; no deitado, embaixo dele.
  def world_label(layout, x, y, caption)
    if layout == :wide
      [ x, y + LABEL_BELOW, "middle" ]
    else
      label_x, anchor = world_label_position(x)
      [ label_x, y + (caption ? 0 : 4), anchor ]
    end
  end

  def world_label_position(x)
    if x > WORLD_MIDDLE
      [ x - LABEL_GAP, "end" ]
    else
      [ x + LABEL_GAP, "start" ]
    end
  end

  def world_node_caption(phase, status)
    case status
    when :completed then "vencida"
    when :current then "você está aqui"
    when :boss then "o chefe espera"
    else "lendária" if phase.legendary?
    end
  end
end
