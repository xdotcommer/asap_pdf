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
    const row = this.element.closest('tr')
    const statusText = status === 'in_review' ? 'In Review' : status === 'done' ? 'Done' : 'Backlog'

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

        // Show success toast notification
        this.showToast(`Document moved to ${statusText}`, 'success')

        // Animate and remove row
        row.classList.add('fade-out-up')
        row.addEventListener('animationend', () => {
          row.remove()
          this.updateStatusCount(status)
        })
      } else {
        // Show error toast notification with all error messages
        const errorMessage = Array.isArray(data.error)
          ? data.error.join(', ')
          : 'Failed to update status'
        this.showToast(errorMessage, 'error')
      }
    })
    .catch(error => {
      console.error('Error:', error)
      this.showToast('Failed to update status', 'error')
    })

    this.hideMenu()
  }

  showToast(message, type = 'success') {
    const toast = document.createElement('div')
    toast.className = 'fixed top-4 right-4 z-50 bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded'
    toast.innerHTML = `<div class="flex items-center"><i class="fas fa-check-circle mr-2"></i>${message}</div>`
    document.body.appendChild(toast)

    // Remove after 3 seconds
    setTimeout(() => {
      toast.style.transition = 'opacity 0.5s'
      toast.style.opacity = '0'
      setTimeout(() => toast.remove(), 500)
    }, 3000)
  }

  updateStatusCount(newStatus) {
    const oldStatus = document.querySelector('input[name="status"]')?.value || ''

    // Helper function to get the correct selector for a status
    const getStatusSelector = (status) => {
      if (status === '') return 'a[href$="status="]'
      return `a[href*="status=${status}"]`
    }

    // Decrement old status count
    const oldStatusElement = document.querySelector(`${getStatusSelector(oldStatus)} span`)
    if (oldStatusElement) {
      const oldCount = parseInt(oldStatusElement.textContent)
      if (!isNaN(oldCount)) {
        oldStatusElement.textContent = oldCount - 1
      }
    }

    // Increment new status count
    const newStatusElement = document.querySelector(`${getStatusSelector(newStatus)} span`)
    if (newStatusElement) {
      const newCount = parseInt(newStatusElement.textContent)
      if (!isNaN(newCount)) {
        newStatusElement.textContent = newCount + 1
      }
    }
  }
}
