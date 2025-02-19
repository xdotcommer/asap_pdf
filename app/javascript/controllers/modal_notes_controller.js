import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["textarea"]
  static values = {
    documentId: Number
  }

  async updateNotes(event) {
    event.preventDefault()
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
            notes: value
          }
        })
      })

      if (!response.ok) {
        throw new Error("Failed to update")
      }

      // Update the notes in the table view if it exists
      const tableNotes = document.querySelector(`[data-text-edit-document-id-value="${this.documentIdValue}"] [data-text-edit-target="display"]`)
      if (tableNotes) {
        tableNotes.textContent = value || "No notes"
      }
    } catch (error) {
      console.error("Error updating notes:", error)
    }
  }
}
