import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // Quando o mapa rola dentro da moldura (no computador), abre na fase atual.
  connect() {
    const here = this.element.querySelector(".world-map__node--current, .world-map__node--boss")
    if (!here || this.element.scrollHeight <= this.element.clientHeight) return

    const frame = this.element.getBoundingClientRect(), node = here.getBoundingClientRect()
    this.element.scrollTop += node.top - frame.top - (frame.height - node.height) / 2
  }

  open({ currentTarget }) {
    const panel = document.getElementById(currentTarget.getAttribute("href").slice(1))
    panel?.querySelector("details")?.setAttribute("open", "")
  }
}
