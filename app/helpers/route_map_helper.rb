module RouteMapHelper
  MAP_WIDTH = 200
  MAP_HEIGHT = 140
  MAP_PADDING = 14

  def route_map(route)
    points = Route::Trace.normalize(route.trace)
    return art_tag(:routes, :placeholder, label: "Rota #{route.name}") if points.empty?

    side = MAP_HEIGHT - 2 * MAP_PADDING
    left = (MAP_WIDTH - side) / 2.0
    coords = points.map { |x, y| [ (left + x * side).round(1), (MAP_PADDING + y * side).round(1) ] }
    id = "route-map-#{route.id}"

    tag.svg(viewBox: "0 0 #{MAP_WIDTH} #{MAP_HEIGHT}", role: "img", class: "route-map",
            "aria-label": "Mapa da rota #{route.name}") do
      safe_join [ route_map_defs(id), route_map_body(id, coords) ]
    end
  end

  private
    def route_map_defs(id)
      tag.defs do
        safe_join [
          tag.linearGradient(id: "#{id}-bg", x1: 0, y1: 0, x2: 0, y2: 1) do
            safe_join [ tag.stop(offset: 0, style: "stop-color: var(--color-deep)"),
                        tag.stop(offset: 1, style: "stop-color: var(--color-panel)") ]
          end,
          tag.filter(id: "#{id}-glow", x: "-20%", y: "-20%", width: "140%", height: "140%") do
            safe_join [ tag.feGaussianBlur(stdDeviation: 3, result: "blur"),
                        tag.feFlood("flood-color": "var(--color-glow)", "flood-opacity": 0.55, result: "tint"),
                        tag.feComposite(in: "tint", in2: "blur", operator: "in", result: "halo"),
                        tag.feMerge { safe_join [ tag.feMergeNode(in: "halo"), tag.feMergeNode(in: "SourceGraphic") ] } ]
          end
        ]
      end
    end

    def route_map_body(id, coords)
      start_x, start_y = coords.first
      safe_join [
        tag.rect(width: MAP_WIDTH, height: MAP_HEIGHT, fill: "url(##{id}-bg)"),
        tag.polyline(points: coords.map { |x, y| "#{x},#{y}" }.join(" "), fill: "none",
                     style: "stroke: var(--color-gold)", "stroke-width": 4,
                     "stroke-linejoin": "round", "stroke-linecap": "round", filter: "url(##{id}-glow)"),
        tag.circle(cx: start_x, cy: start_y, r: 5, style: "fill: var(--color-glow); stroke: var(--color-gold)",
                   "stroke-width": 2)
      ]
    end
end
