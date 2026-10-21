class Trail
  SAMPLE_STEP = 0.02

  PHASE = [
    [ 28, 268 ], [ 75, 255 ], [ 120, 238 ], [ 96, 205 ], [ 140, 185 ],
    [ 192, 172 ], [ 182, 132 ], [ 222, 100 ], [ 250, 64 ]
  ].freeze

  WORLD = [
    [ 140, 570 ], [ 70, 520 ], [ 60, 460 ], [ 130, 410 ], [ 210, 360 ],
    [ 220, 290 ], [ 140, 240 ], [ 60, 190 ], [ 100, 120 ], [ 140, 60 ]
  ].freeze

  def initialize(points)
    @points = points
    @segments = points.each_cons(2).map { |a, b| [ a, b, Math.hypot(b[0] - a[0], b[1] - a[1]) ] }
    @length = @segments.sum { |_, _, size| size }
  end

  def point_at(fraction)
    remaining = fraction.clamp(0, 1) * @length

    @segments.each do |from, to, size|
      return interpolate(from, to, size.zero? ? 0 : remaining / size) if remaining <= size
      remaining -= size
    end

    @points.last
  end

  def path_d(from: 0, to: 1)
    points = samples(from, to)
    curves = points[1..-2].each_cons(2).map { |a, b| "Q #{format_point(a)} #{format_point(midpoint(a, b))}" }
    [ "M #{format_point(points.first)}", *curves, "L #{format_point(points.last)}" ].join(" ")
  end

  private
    def samples(from, to)
      steps = [ ((to - from) / SAMPLE_STEP).ceil, 2 ].max
      Array.new(steps + 1) { |i| point_at(from + (to - from) * i / steps.to_f) }
    end

    def interpolate(a, b, t)
      [ a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t ]
    end

    def midpoint(a, b)
      interpolate(a, b, 0.5)
    end

    def format_point(point)
      point.map { |n| n.to_f.round(1) }.join(" ")
    end
end
