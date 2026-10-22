import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "km" ]

  fill(event) {
    const km = event.target.selectedOptions[0]?.dataset.km
    if (km) this.kmTarget.value = km
  }
}
