import { Controller } from "@hotwired/stimulus"

// Tira o traçado da rota do print do Samsung Health: acha a linha laranja e
// vermelha, ordena, simplifica e normaliza igual a Route::Trace.normalize.
const SCALED_WIDTH = 360
const TOP_SKIP = 0.09
const BOTTOM_SKIP = 0.12
const CELL = 4
const CELL_MIN_PIXELS = 3
const MIN_COMPONENT_CELLS = 12
const MAX_GAP_CELLS = 4
const MAX_POINTS = 300
const TAP_DISTANCE = 70
const TAP_RADIUS = 3

const MAP_WIDTH = 200
const MAP_HEIGHT = 140
const MAP_PADDING = 14
const SVG = "http://www.w3.org/2000/svg"

export default class extends Controller {
  static targets = [ "file", "canvas", "preview", "field", "retry" ]

  load() {
    const file = this.fileTarget.files[0]
    if (!file) return

    const image = new Image()
    image.onload = () => {
      this.scale = SCALED_WIDTH / image.naturalWidth
      this.canvasTarget.width = SCALED_WIDTH
      this.canvasTarget.height = Math.round(image.naturalHeight * this.scale)
      this.canvasTarget.getContext("2d", { willReadFrequently: true })
        .drawImage(image, 0, 0, this.canvasTarget.width, this.canvasTarget.height)
      this.canvasTarget.hidden = false
      URL.revokeObjectURL(image.src)
      this.extract()
    }
    image.src = URL.createObjectURL(file)
  }

  pick(event) {
    if (!this.scale) return

    const canvas = this.canvasTarget
    const x = Math.round(event.offsetX * canvas.width / canvas.clientWidth)
    const y = Math.round(event.offsetY * canvas.height / canvas.clientHeight)
    this.extract(this.colorNear(x, y))
  }

  extract(color) {
    const { width, height } = this.canvasTarget
    const image = this.canvasTarget.getContext("2d", { willReadFrequently: true }).getImageData(0, 0, width, height)
    const cells = orderCells(litCells(image, color), Math.floor(height / CELL))
    const points = simplify(cells).slice(0, MAX_POINTS)
      .map(([ x, y ]) => [ (x * CELL + CELL / 2) / this.scale, (y * CELL + CELL / 2) / this.scale ])

    if (points.length < 2) {
      this.show([], "empty")
    } else {
      const xs = points.map(([ x ]) => x), ys = points.map(([ , y ]) => y)
      this.element.dataset.traceBounds = [ Math.min(...xs), Math.min(...ys), Math.max(...xs), Math.max(...ys) ]
        .map(Math.round).join(",")
      this.show(normalize(points), "ok")
    }
  }

  show(points, status) {
    this.fieldTarget.value = points.length ? JSON.stringify(points) : ""
    this.previewTarget.replaceChildren(...(points.length ? [ routeMap(points) ] : []))
    this.retryTarget.hidden = false
    this.retryTarget.textContent = status === "ok" ? "Saiu errado? Toque na linha do trajeto." : "Tocar na linha do trajeto"
    this.retryTarget.classList.toggle("caption", status === "ok")
    this.retryTarget.classList.toggle("text-gold", status === "empty")
    this.element.dataset.traceStatus = status
  }

  // O dedo raramente acerta o meio da linha: usa a cor mais forte em volta.
  colorNear(x, y) {
    const context = this.canvasTarget.getContext("2d", { willReadFrequently: true })
    const { data } = context.getImageData(x - TAP_RADIUS, y - TAP_RADIUS, TAP_RADIUS * 2 + 1, TAP_RADIUS * 2 + 1)
    let color = null, strongest = -1

    for (let i = 0; i < data.length; i += 4) {
      const [ r, g, b ] = [ data[i], data[i + 1], data[i + 2] ]
      const { saturation } = hsv(r, g, b)
      if (saturation > strongest) { strongest = saturation; color = [ r, g, b ] }
    }
    return color
  }
}

function hsv(r, g, b) {
  const max = Math.max(r, g, b), min = Math.min(r, g, b), delta = max - min
  let hue = 0
  if (delta > 0) {
    if (max === r) hue = (60 * ((g - b) / delta) + 360) % 360
    else if (max === g) hue = 60 * ((b - r) / delta) + 120
    else hue = 60 * ((r - g) / delta) + 240
  }
  return { hue, saturation: max === 0 ? 0 : delta / max, value: max / 255 }
}

function isRouteColor(r, g, b) {
  const { hue, saturation, value } = hsv(r, g, b)
  return saturation >= 0.55 && value >= 0.45 && (hue <= 45 || hue >= 340)
}

function maskFor(color) {
  if (!color) return isRouteColor
  return (r, g, b) => Math.hypot(r - color[0], g - color[1], b - color[2]) < TAP_DISTANCE
}

function litCells({ data, width, height }, color) {
  const matches = maskFor(color)
  const cols = Math.floor(width / CELL)
  const top = Math.ceil(height * TOP_SKIP), bottom = Math.floor(height * (1 - BOTTOM_SKIP))
  const counts = new Map()

  for (let y = top; y < bottom; y++) {
    for (let x = 0; x < cols * CELL; x++) {
      const i = (y * width + x) * 4
      if (matches(data[i], data[i + 1], data[i + 2])) {
        const key = Math.floor(y / CELL) * cols + Math.floor(x / CELL)
        counts.set(key, (counts.get(key) || 0) + 1)
      }
    }
  }

  const lit = new Set([ ...counts ].filter(([ , count ]) => count >= CELL_MIN_PIXELS).map(([ key ]) => key))
  return withoutSmallComponents(lit, cols).map(key => [ key % cols, Math.floor(key / cols) ])
}

function withoutSmallComponents(lit, cols) {
  const seen = new Set(), kept = []

  for (const start of lit) {
    if (seen.has(start)) continue
    const component = [ start ]
    seen.add(start)

    for (let i = 0; i < component.length; i++) {
      const x = component[i] % cols, y = Math.floor(component[i] / cols)
      for (let dy = -1; dy <= 1; dy++) {
        for (let dx = -1; dx <= 1; dx++) {
          const key = (y + dy) * cols + x + dx
          if (x + dx >= 0 && x + dx < cols && lit.has(key) && !seen.has(key)) {
            seen.add(key)
            component.push(key)
          }
        }
      }
    }
    if (component.length >= MIN_COMPONENT_CELLS) kept.push(...component)
  }
  return kept
}

// Começa no canto inferior esquerdo e vai sempre pra vizinha mais perto.
function orderCells(cells, rows) {
  const left = [ ...cells ], path = []
  let current = nearest(left, [ 0, rows ])

  while (current) {
    path.push(current)
    left.splice(left.indexOf(current), 1)
    const next = nearest(left, current)
    current = next && distance(next, current) <= MAX_GAP_CELLS ? next : null
  }
  return path
}

function nearest(cells, point) {
  let best = null, bestDistance = Infinity
  for (const cell of cells) {
    const d = distance(cell, point)
    if (d < bestDistance) { best = cell; bestDistance = d }
  }
  return best
}

function distance([ ax, ay ], [ bx, by ]) {
  return Math.hypot(ax - bx, ay - by)
}

// Ramer–Douglas–Peucker, epsilon em células.
function simplify(points, epsilon = 1) {
  if (points.length < 3) return points

  const first = points[0], last = points[points.length - 1]
  let index = 0, farthest = 0
  for (let i = 1; i < points.length - 1; i++) {
    const d = distanceToSegment(points[i], first, last)
    if (d > farthest) { farthest = d; index = i }
  }

  if (farthest <= epsilon) return [ first, last ]
  return [ ...simplify(points.slice(0, index + 1), epsilon).slice(0, -1), ...simplify(points.slice(index), epsilon) ]
}

function distanceToSegment(point, a, b) {
  const length = distance(a, b)
  if (length === 0) return distance(point, a)
  return Math.abs((b[0] - a[0]) * (a[1] - point[1]) - (a[0] - point[0]) * (b[1] - a[1])) / length
}

// Mesma regra de Route::Trace.normalize.
function normalize(points) {
  const xs = points.map(([ x ]) => x), ys = points.map(([ , y ]) => y)
  const minX = Math.min(...xs), minY = Math.min(...ys)
  const width = Math.max(...xs) - minX, height = Math.max(...ys) - minY
  const side = Math.max(width, height)
  const offsetX = (side - width) / 2, offsetY = (side - height) / 2
  const round = value => Math.round(value * 10000) / 10000

  return points.map(([ x, y ]) =>
    side === 0 ? [ 0.5, 0.5 ] : [ round((x - minX + offsetX) / side), round((y - minY + offsetY) / side) ])
}

// Mesmo desenho de RouteMapHelper#route_map.
function routeMap(points) {
  const side = MAP_HEIGHT - 2 * MAP_PADDING
  const left = (MAP_WIDTH - side) / 2
  const coords = points.map(([ x, y ]) => [ round1(left + x * side), round1(MAP_PADDING + y * side) ])
  const id = "route-map-preview"

  return svg("svg", { viewBox: `0 0 ${MAP_WIDTH} ${MAP_HEIGHT}`, role: "img", class: "route-map", "aria-label": "Prévia do mapa da rota" }, [
    svg("defs", {}, [
      svg("linearGradient", { id: `${id}-bg`, x1: 0, y1: 0, x2: 0, y2: 1 }, [
        svg("stop", { offset: 0, style: "stop-color: var(--color-deep)" }),
        svg("stop", { offset: 1, style: "stop-color: var(--color-panel)" })
      ]),
      svg("filter", { id: `${id}-glow`, filterUnits: "userSpaceOnUse", x: 0, y: 0, width: MAP_WIDTH, height: MAP_HEIGHT }, [
        svg("feGaussianBlur", { stdDeviation: 3, result: "blur" }),
        svg("feFlood", { style: "flood-color: var(--color-glow)", "flood-opacity": 0.55, result: "tint" }),
        svg("feComposite", { in: "tint", in2: "blur", operator: "in", result: "halo" }),
        svg("feMerge", {}, [ svg("feMergeNode", { in: "halo" }), svg("feMergeNode", { in: "SourceGraphic" }) ])
      ])
    ]),
    svg("rect", { width: MAP_WIDTH, height: MAP_HEIGHT, fill: `url(#${id}-bg)` }),
    svg("polyline", { points: coords.map(([ x, y ]) => `${x},${y}`).join(" "), fill: "none",
      style: "stroke: var(--color-gold)", "stroke-width": 4, "stroke-linejoin": "round", "stroke-linecap": "round",
      filter: `url(#${id}-glow)` }),
    svg("circle", { cx: coords[0][0], cy: coords[0][1], r: 5, style: "fill: var(--color-glow); stroke: var(--color-gold)",
      "stroke-width": 2 })
  ])
}

function svg(name, attributes, children = []) {
  const element = document.createElementNS(SVG, name)
  for (const [ key, value ] of Object.entries(attributes)) element.setAttribute(key, value)
  element.append(...children)
  return element
}

function round1(value) {
  return Math.round(value * 10) / 10
}
