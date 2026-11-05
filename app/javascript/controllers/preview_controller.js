import { Controller } from "@hotwired/stimulus"

const DELAY_MS = 300

// Live Markdown preview: the server renders it, so it always matches the published page.
export default class extends Controller {
  static values = { url: String, language: String }

  schedule({ target }) {
    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.#refresh(target.value), DELAY_MS)
  }

  disconnect() {
    clearTimeout(this.timer)
    this.request?.abort()
  }

  async #refresh(body) {
    // Cancels the previous request, so a slow response can't overwrite newer text.
    this.request?.abort()
    this.request = new AbortController()
    try {
      const response = await fetch(this.urlValue, {
        method: "POST",
        signal: this.request.signal,
        headers: {
          Accept: "text/vnd.turbo-stream.html",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content ?? ""
        },
        body: new URLSearchParams({ language: this.languageValue, body })
      })
      if (response.ok) window.Turbo.renderStreamMessage(await response.text())
    } catch (error) {
      if (error.name !== "AbortError") throw error
    }
  }
}
