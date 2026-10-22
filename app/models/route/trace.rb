# Trace é a lista de pontos [x, y] do desenho de uma rota. A regra de
# normalização é a mesma do JS que importa o trace: proporção preservada.
module Route::Trace
  MAX_POINTS = 300
  PRECISION = 4

  def self.valid?(value)
    value.is_a?(Array) && value.size.between?(2, MAX_POINTS) &&
      value.all? { |point| point.is_a?(Array) && point.size == 2 && point.all?(Numeric) }
  end

  def self.normalize(points)
    return [] unless points.is_a?(Array) && points.size >= 2

    xs, ys = points.map(&:first), points.map(&:last)
    side = [ xs.max - xs.min, ys.max - ys.min ].max.to_f
    offset_x = (side - (xs.max - xs.min)) / 2
    offset_y = (side - (ys.max - ys.min)) / 2

    points.map do |x, y|
      if side.zero?
        [ 0.5, 0.5 ]
      else
        [ ((x - xs.min + offset_x) / side).round(PRECISION), ((y - ys.min + offset_y) / side).round(PRECISION) ]
      end
    end
  end
end
