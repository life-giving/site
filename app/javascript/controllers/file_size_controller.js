import { Controller } from "@hotwired/stimulus"

// Warns before a slow upload that the server would reject anyway. The server still enforces the limits.
export default class extends Controller {
  static targets = ["message"]
  static values = { maxMb: Number, template: String, maxFiles: Number, tooMany: String }

  check({ target }) {
    const message = this.#problem(Array.from(target.files))
    target.setCustomValidity(message)
    this.messageTarget.textContent = message
    this.messageTarget.hidden = !message
  }

  #problem(files) {
    if (this.hasMaxFilesValue && files.length > this.maxFilesValue) return this.tooManyValue
    const tooLarge = files.find((file) => file.size > this.maxMbValue * 1048576)
    return tooLarge ? this.templateValue.replace("%{name}", tooLarge.name) : ""
  }
}
