import { Controller } from "@hotwired/stimulus"

// Language tabs in the news editor. Both panels stay in the form, so both are submitted.
export default class extends Controller {
  static targets = ["tab", "panel"]

  show({ currentTarget }) {
    const language = currentTarget.dataset.language
    this.tabTargets.forEach((tab) => tab.setAttribute("aria-pressed", String(tab === currentTarget)))
    this.panelTargets.forEach((panel) => { panel.hidden = panel.dataset.language !== language })
  }
}
