import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["button", "preloader", "display"]

    static values = {
        documentId: Number,
    }

    async getHtml() {
        try {
            this.buttonTarget.classList.add('hidden');
            this.preloaderTarget.classList.remove('hidden')
            const response = await fetch(`/documents/${this.documentIdValue}/update_html`, {
                method: "PATCH",
                headers: {
                    "Content-Type": "application/json",
                    "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
                    "Accept": "application/json"
                },
            })
            if (response.ok) {
                const jsonHTML = await response.json()
                this.displayTarget.innerHTML = jsonHTML.display_text;
                this.preloaderTarget.classList.add('hidden')
            } else {
                this.displayTarget.innerHTML = 'An error occurred creating html for this document. Please try again later.';
                throw new Error("Response was not OK")
            }
        } catch (error) {
            console.error("Error creating html for document:", error)
            this.preloaderTarget.classList.add('hidden')
        }
    }
}
