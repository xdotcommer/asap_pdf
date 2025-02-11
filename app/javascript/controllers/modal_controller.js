import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  submitAndClose(event) {
    // Let the form submit normally
    // The modal will close automatically when redirected after successful submission
    const modal = document.getElementById('add_site_modal')
    if (modal) {
      modal.addEventListener('turbo:submit-end', () => {
        modal.close()
      }, { once: true })
    }
  }
}
