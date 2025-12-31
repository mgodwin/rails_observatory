import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['input', 'results']
  static values = {
    autocompleteUrl: String
  }

  connect() {
    this.metrics = []
    this.selectedIndex = -1
    this.fetchMetrics()
  }

  async fetchMetrics() {
    try {
      const response = await fetch(this.autocompleteUrlValue)
      this.metrics = await response.json()
    } catch (error) {
      console.error('Failed to fetch metrics:', error)
    }
  }

  onInput(event) {
    const query = event.target.value.toLowerCase()
    this.selectedIndex = -1
    this.showResults(query)
  }

  onFocus() {
    const query = this.inputTarget.value.toLowerCase()
    this.showResults(query)
  }

  onBlur() {
    // Delay hiding to allow click events on results
    setTimeout(() => {
      this.resultsTarget.hidden = true
    }, 200)
  }

  onKeydown(event) {
    const results = this.resultsTarget.querySelectorAll('li')

    switch (event.key) {
      case 'ArrowDown':
        event.preventDefault()
        this.selectedIndex = Math.min(this.selectedIndex + 1, results.length - 1)
        this.updateSelection(results)
        break
      case 'ArrowUp':
        event.preventDefault()
        this.selectedIndex = Math.max(this.selectedIndex - 1, -1)
        this.updateSelection(results)
        break
      case 'Enter':
        event.preventDefault()
        if (this.selectedIndex >= 0 && results[this.selectedIndex]) {
          const link = results[this.selectedIndex].querySelector('a')
          if (link) window.location.href = link.href
        } else if (this.inputTarget.value) {
          // Navigate to the typed metric if it exists
          const query = this.inputTarget.value.toLowerCase()
          const exactMatch = this.metrics.find(m => m.toLowerCase() === query)
          if (exactMatch) {
            window.location.href = `?metric=${encodeURIComponent(exactMatch)}`
          }
        }
        break
      case 'Escape':
        this.resultsTarget.hidden = true
        this.inputTarget.blur()
        break
    }
  }

  updateSelection(results) {
    results.forEach((li, index) => {
      if (index === this.selectedIndex) {
        li.classList.add('selected')
        li.scrollIntoView({ block: 'nearest' })
      } else {
        li.classList.remove('selected')
      }
    })
  }

  showResults(query) {
    const filtered = query.length > 0
      ? this.metrics.filter(m => m.toLowerCase().includes(query))
      : this.metrics

    if (filtered.length === 0) {
      this.resultsTarget.hidden = true
      return
    }

    this.resultsTarget.innerHTML = filtered.slice(0, 20).map(metric =>
      `<li><a href="?metric=${encodeURIComponent(metric)}">${this.highlight(metric, query)}</a></li>`
    ).join('')

    this.resultsTarget.hidden = false
  }

  highlight(text, query) {
    if (!query) return text
    const regex = new RegExp(`(${this.escapeRegex(query)})`, 'gi')
    return text.replace(regex, '<mark>$1</mark>')
  }

  escapeRegex(string) {
    return string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
  }
}
