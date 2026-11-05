import { Controller } from "@hotwired/stimulus"

// Mobile navigation behind the burger button.
export default class extends Controller {
  static targets = ["button"]

  toggle() {
    this.#set(!this.element.classList.contains("is-open"))
  }

  close() {
    this.#set(false)
  }

  closeOnEscape(event) {
    if (event.key === "Escape") this.close()
  }

  #set(open) {
    this.element.classList.toggle("is-open", open)
    this.buttonTarget.setAttribute("aria-expanded", String(open))
  }
}
