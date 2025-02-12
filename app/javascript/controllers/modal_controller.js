import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["pdfView", "metadataView", "pdfButton", "metadataButton"]

  connect() {
    // Initialize with PDF view
    this.showPdfView()
  }

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

  showPdfView() {
    this.pdfViewTarget.classList.remove("hidden")
    this.metadataViewTarget.classList.add("hidden")
    this.pdfButtonTarget.classList.add("bg-primary-100", "text-primary-700")
    this.pdfButtonTarget.classList.remove("bg-gray-100", "text-gray-700")
    this.metadataButtonTarget.classList.add("bg-gray-100", "text-gray-700")
    this.metadataButtonTarget.classList.remove("bg-primary-100", "text-primary-700")
  }

  showMetadataView() {
    this.pdfViewTarget.classList.add("hidden")
    this.metadataViewTarget.classList.remove("hidden")
    this.metadataButtonTarget.classList.add("bg-primary-100", "text-primary-700")
    this.metadataButtonTarget.classList.remove("bg-gray-100", "text-gray-700")
    this.pdfButtonTarget.classList.add("bg-gray-100", "text-gray-700")
    this.pdfButtonTarget.classList.remove("bg-primary-100", "text-primary-700")
  }
}
