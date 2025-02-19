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
    const colors = type === 'success'
      ? 'bg-green-100 border-green-400 text-green-700'
      : 'bg-red-100 border-red-400 text-red-700'
    const icon = type === 'success'
      ? 'fa-check-circle'
      : 'fa-exclamation-circle'

    const toastHtml = `
      <div data-controller="toast">
        <div data-toast-target="container" class="fixed top-4 right-4 z-50 ${colors} px-4 py-3 rounded border">
          <div class="flex items-center">
            <div class="py-1"><i class="fas ${icon} mr-2"></i>${message}</div>
          </div>
        </div>
      </div>
    `
    document.body.insertAdjacentHTML('beforeend', toastHtml)
    const toastElement = document.body.lastElementChild
    const toastController = application.getControllerForElementAndIdentifier(toastElement, 'toast')
    toastController.show()
  }

  updateStatusCount(newStatus) {
    const oldStatus = document.querySelector('input[name="status"]')?.value || ''

    // Decrement old status count
    const oldStatusElement = document.querySelector(`a[href*="status=${oldStatus}"] span`)
    if (oldStatusElement) {
      const oldCount = parseInt(oldStatusElement.textContent)
      oldStatusElement.textContent = oldCount - 1
    }

    // Increment new status count
    const newStatusElement = document.querySelector(`a[href*="status=${newStatus}"] span`)
    if (newStatusElement) {
      const newCount = parseInt(newStatusElement.textContent)
      newStatusElement.textContent = newCount + 1
    }
  }
}
