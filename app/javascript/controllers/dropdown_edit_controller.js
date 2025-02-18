import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "select"]
  static values = {
    documentId: Number,
    field: String
  }

  connect() {
    // Hide select by default, show display
    if (this.hasSelectTarget) {
      this.selectTarget.classList.add("hidden")
    }
    // Add click outside listener
    document.addEventListener("click", this.handleClickOutside.bind(this))
  }

  disconnect() {
    // Clean up click outside listener
    document.removeEventListener("click", this.handleClickOutside.bind(this))
  }

  showSelect(event) {
    event.stopPropagation()
    this.displayTarget.classList.add("hidden")
    this.selectTarget.classList.remove("hidden")
    this.selectTarget.focus()
  }

  hideSelect() {
    this.displayTarget.classList.remove("hidden")
    this.selectTarget.classList.add("hidden")
  }

  handleClickOutside(event) {
    if (this.element && !this.element.contains(event.target)) {
      this.hideSelect()
    }
  }

  async updateValue(event) {
    const value = event.target.value
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

    if (!csrfToken) {
      console.error('CSRF token not found')
      return
    }

    try {
      const response = await fetch(`/documents/${this.documentIdValue}/update_${this.fieldValue}`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': csrfToken
        },
        body: JSON.stringify({ value: value })
      })

      if (response.ok) {
        const data = await response.json()
        // Preserve the magic wand icon when updating display text
        const icon = this.displayTarget.querySelector('i')
        this.displayTarget.innerHTML = ''
        if (icon) {
          const span = document.createElement('span')
          span.className = 'text-xs font-normal'
          span.appendChild(icon)
          this.displayTarget.appendChild(span)
        }
        this.displayTarget.appendChild(document.createTextNode(' ' + data.display_text))
        this.hideSelect()

        // Add success animations
        this.displayTarget.classList.add('success-animation')

        // Create and add success icon
        const successIcon = document.createElement('i')
        successIcon.className = 'fas fa-check text-success text-xs ml-1 success-icon'
        this.displayTarget.appendChild(successIcon)

        // Remove scale animation after it completes
        setTimeout(() => {
          this.displayTarget.classList.remove('success-animation')
        }, 500)

        // Remove success icon after fade animation
        setTimeout(() => {
          successIcon.remove()
        }, 800)
      } else {
        console.error('Failed to update value:', await response.text())
      }
    } catch (error) {
      console.error('Error updating value:', error)
    }
  }
}
