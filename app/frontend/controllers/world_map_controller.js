import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  open({ currentTarget }) {
    const panel = document.getElementById(currentTarget.getAttribute("href").slice(1))
    panel?.querySelector("details")?.setAttribute("open", "")
  }
}
