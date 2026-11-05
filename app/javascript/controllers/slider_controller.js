import { Controller } from "@hotwired/stimulus"

// Gallery: buttons page by one frame and wrap around; swiping is native and the counter follows the scroll.
export default class extends Controller {
  static targets = ["track", "count"]

  next() {
    this.#page(1)
  }

  previous() {
    this.#page(-1)
  }

  update() {
    if (this.pending || !this.hasCountTarget) return
    this.pending = true
    requestAnimationFrame(() => {
      this.pending = false
      const track = this.trackTarget
      this.countTarget.textContent = `${Math.round(track.scrollLeft / track.clientWidth) + 1} / ${track.children.length}`
    })
  }

  #page(direction) {
    const track = this.trackTarget
    const atEnd = track.scrollLeft + track.clientWidth >= track.scrollWidth - 1
    if (direction > 0 && atEnd) track.scrollTo({ left: 0 })
    else if (direction < 0 && track.scrollLeft <= 0) track.scrollTo({ left: track.scrollWidth })
    else track.scrollBy({ left: direction * track.clientWidth })
  }
}
