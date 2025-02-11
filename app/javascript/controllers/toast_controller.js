import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container"]

  connect() {
    // If there's a message on connect, show it
    if (this.hasContainerTarget && this.containerTarget.textContent.trim()) {
      this.show()
    }
  }

  show() {
    // Add animation classes
    this.containerTarget.classList.remove("hidden")
    this.containerTarget.classList.add("transform", "translate-y-0", "opacity-100")

    // Set timeout to hide
    setTimeout(() => {
      this.hide()
    }, 5000)
  }

  hide() {
    this.containerTarget.classList.remove("translate-y-0", "opacity-100")
    this.containerTarget.classList.add("transform", "-translate-y-full", "opacity-0")

    // Remove from DOM after animation
    setTimeout(() => {
      this.containerTarget.remove()
    }, 500)
  }
}
