import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { steps: Number, rise: { type: Number, default: 0.17 } }
  static targets = [ "climbs", "output", "steps" ]

  connect() {
    this.update()
  }

  fill({ params: { climbs } }) {
    this.climbsTarget.value = climbs
    this.update()
  }

  update() {
    const steps = this.hasStepsTarget ? parseInt(this.stepsTarget.value, 10) : this.stepsValue
    const climbs = parseInt(this.climbsTarget.value, 10)

    if (steps > 0 && climbs > 0) {
      const meters = Math.round(climbs * steps * this.riseValue)
      this.outputTarget.textContent = `≈ ${meters} m de desnível`
    } else {
      this.outputTarget.textContent = ""
    }
  }
}
