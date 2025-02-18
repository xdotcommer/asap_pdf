import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "textarea"]
  static values = {
    documentId: Number,
    field: String
  }

  showTextarea(event) {
    this.displayTarget.classList.add("hidden")
    this.textareaTarget.classList.remove("hidden")
    this.textareaTarget.focus()

    // Auto-size textarea to content
    this.textareaTarget.style.height = "auto"
    this.textareaTarget.style.height = this.textareaTarget.scrollHeight + "px"
  }

  hideTextarea() {
    this.displayTarget.classList.remove("hidden")
    this.textareaTarget.classList.add("hidden")
  }

  async updateValue(event) {
    if (event.type === "keydown" && event.key === "Escape") {
      this.hideTextarea()
      return
    }

    if (event.type === "keydown" && event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      this.textareaTarget.blur()
      return
    }

    if (event.type === "blur" || (event.type === "keydown" && event.key === "Enter" && !event.shiftKey)) {
      const value = this.textareaTarget.value.trim()

      try {
        const response = await fetch(`/documents/${this.documentIdValue}/update_notes`, {
          method: "PATCH",
          headers: {
            "Content-Type": "application/json",
            "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
            "Accept": "application/json"
          },
          body: JSON.stringify({
            document: {
              [this.fieldValue]: value
            }
          })
        })

        if (response.ok) {
          this.displayTarget.textContent = value || "No notes"
          this.hideTextarea()
        } else {
          throw new Error("Failed to update")
        }
      } catch (error) {
        console.error("Error updating value:", error)
        // Revert to original value
        this.textareaTarget.value = this.displayTarget.textContent
        this.hideTextarea()
      }
    }
  }

  // Handle auto-sizing of textarea as user types
  adjustHeight(event) {
    const textarea = event.target
    textarea.style.height = "auto"
    textarea.style.height = textarea.scrollHeight + "px"
  }
}
