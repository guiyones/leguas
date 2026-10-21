module MapsHelper
  WORLD_TRAIL = Trail.new(Trail::WORLD)
  WORLD_MIDDLE = 140
  LABEL_GAP = 18

  def world_trail = WORLD_TRAIL

  def world_nodes(region)
    last = [ region.phases.size - 1, 1 ].max
    region.phases.each_with_index.map { |phase, index| [ phase, WORLD_TRAIL.point_at(index / last.to_f).map { it.round(1) } ] }
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
