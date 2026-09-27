import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "step", "back", "next", "submit" ]

  connect() {
    this.show(this.firstStepWithError())
  }

  next() {
    if (this.currentStepIsValid()) this.show(this.index + 1)
  }

  back() {
    this.show(this.index - 1)
  }

  show(index) {
    this.index = Math.max(0, Math.min(index, this.stepTargets.length - 1))
    this.stepTargets.forEach((step, i) => step.hidden = i !== this.index)

    const last = this.index === this.stepTargets.length - 1
    this.backTarget.hidden = this.index === 0
    this.nextTarget.hidden = last
    this.submitTarget.hidden = !last
  }

  currentStepIsValid() {
    return [ ...this.stepTargets[this.index].querySelectorAll("input") ].every(input => input.reportValidity())
  }

  firstStepWithError() {
    const index = this.stepTargets.findIndex(step => step.querySelector(".field-error"))
    return index === -1 ? 0 : index
  }
}
