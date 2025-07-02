import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  async fetch () {
    const response = await fetch(this.url)
    if (!response.ok) {
      throw new Error('Error refreshing')
    } else {
      const completeEvent = this.dispatch('complete')
      if (!completeEvent.defaultPrevented) {
        this.element.innerHTML = await response.text()
      }
    }
  }

  loop () {
    setTimeout(() => this.fetchAndLoop(), this.refreshInterval)
  }

  fetchAndLoop () {
    this.fetch().then(() => this.loop())
  }

  get refreshInterval () {
    return Number(this.element.dataset.refreshInterval)
  }

  get url () {
    return this.element.dataset.url
  }

  connect () {
    // this.fetchAndLoop()
  }
}