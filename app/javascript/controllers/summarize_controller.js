import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["display", "button", "preloader"]

    static values = {
        documentId: Number,
    }

    async getSummary() {
        console.log('getSummary called with document ID:', this.documentIdValue)
        try {
            this.buttonTarget.classList.add('hidden');
            this.preloaderTarget.classList.remove('hidden')
            const response = await fetch(`/documents/${this.documentIdValue}/update_summary`, {
                method: "PATCH",
                headers: {
                    "Content-Type": "application/json",
                    "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
                    "Accept": "application/json"
                },
            })
            if (response.ok) {
                const jsonSummary = await response.json()
                this.displayTarget.textContent = jsonSummary.display_text;
                this.preloaderTarget.classList.add('hidden')
            } else {
                this.displayTarget.textContent = 'An error occurred summarizing this document. Please try again later.';
                throw new Error("Response was not OK")
            }
        } catch (error) {
            console.error("Error summarizing document:", error)
            this.preloaderTarget.classList.add('hidden')
        }
    }
}
