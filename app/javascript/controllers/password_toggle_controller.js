import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "icon"]

  initialize() {
    console.log("Password toggle controller initialized")
  }

  connect() {
    console.log("Password toggle controller connected", {
      element: this.element,
      hasInputTarget: this.hasInputTarget,
      hasIconTarget: this.hasIconTarget
    })

    try {
      if (!this.hasInputTarget) {
        console.error("Missing input target. Add data-password-toggle-target='input' to your input element")
      }
      if (!this.hasIconTarget) {
        console.error("Missing icon target. Add data-password-toggle-target='icon' to your icon element")
      }
    } catch (e) {
      console.error("Error in connect:", e)
    }
  }

  toggle(event) {
    try {
      console.log("Toggle called", {
        event,
        element: this.element,
        input: this.hasInputTarget ? this.inputTarget : null,
        icon: this.hasIconTarget ? this.iconTarget : null
      })

      if (!this.hasInputTarget || !this.hasIconTarget) {
        console.error("Missing required targets")
        return
      }

      this.inputTarget.type = this.inputTarget.type === "password" ? "text" : "password"
      this.iconTarget.classList.toggle("fa-eye")
      this.iconTarget.classList.toggle("fa-eye-slash")

      console.log("Toggle completed", {
        newType: this.inputTarget.type,
        iconClasses: this.iconTarget.classList.toString()
      })
    } catch (e) {
      console.error("Error in toggle:", e)
    }
  }
}
