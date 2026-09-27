module PixelArtHelper
  def pixel_art_tag(art, size:, label:, silhouette: false, **options)
    rects = art.runs.map do |x, y, width, char|
      tag.rect x: x, y: y, width: width, height: 1, fill: silhouette ? "var(--color-silhouette)" : art.color(char)
    end

    tag.svg safe_join(rects), viewBox: "0 0 #{art.width} #{art.height}", width: size, height: size,
      "shape-rendering": "crispEdges", role: "img", "aria-label": label, **options
  end
end
