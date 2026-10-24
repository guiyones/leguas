import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "km", "hours", "minutes", "seconds" ]

  fill(event) {
    const { km, durationS } = event.target.selectedOptions[0]?.dataset ?? {}
    if (km) this.kmTarget.value = km
    if (this.hasHoursTarget && event.target.value) this.fillDuration(Number(durationS ?? 0))
  }

  fillDuration(total) {
    const hours = Math.floor(total / 3600)
    const minutes = Math.floor(total % 3600 / 60)
    const seconds = total % 60
    this.hoursTarget.value = hours || ""
    this.minutesTarget.value = total ? minutes : ""
    this.secondsTarget.value = seconds || ""
  }
}
