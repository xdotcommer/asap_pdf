import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  connect() {
    // Close menu when clicking outside
    document.addEventListener('click', (e) => {
      if (!this.element.contains(e.target)) {
        this.hideMenu()
      }
    })
  }

  toggleMenu(event) {
    event.preventDefault()
    event.stopPropagation()

    const menu = this.menuTarget
    const isHidden = menu.classList.contains('hidden')

    if (isHidden) {
      this.showMenu()
    } else {
      this.hideMenu()
    }
  }

  showMenu() {
    this.menuTarget.classList.remove('hidden')
  }

  hideMenu() {
    this.menuTarget.classList.add('hidden')
  }

  updateStatus(event) {
    event.preventDefault()
    const status = event.currentTarget.dataset.status
    const documentId = this.element.dataset.documentId
    const siteId = document.querySelector('meta[name="site-id"]').content

    fetch(`/sites/${siteId}/documents/${documentId}/update_status`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({ status })
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        // Update hidden status field in filter form if it exists
        const hiddenStatus = document.querySelector('input[name="status"]')
        if (hiddenStatus) {
          hiddenStatus.value = status || ''
        }

        // Refresh the page to update counts
        window.location.reload()
      }
    })

    this.hideMenu()
  }
}
