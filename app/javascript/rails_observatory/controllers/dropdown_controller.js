import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['button', 'menu', 'option']
  static values = {
    open: { type: Boolean, default: false }
  }

  connect() {
    this.selectedIndex = -1
    this.boundHandleClickOutside = this.handleClickOutside.bind(this)
  }

  disconnect() {
    document.removeEventListener('click', this.boundHandleClickOutside)
  }

  toggle(event) {
    // Ignore if triggered by keyboard (Enter/Space generate click events on buttons)
    // Keyboard handling is done in onButtonKeydown
    if (event.detail === 0) return

    event.preventDefault()
    if (this.openValue) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    this.openValue = true
    this.buttonTarget.setAttribute('aria-expanded', 'true')
    document.addEventListener('click', this.boundHandleClickOutside)
    // Focus first option or active option (deferred to run after click event completes)
    requestAnimationFrame(() => {
      const activeIndex = this.optionTargets.findIndex(opt => opt.classList.contains('active'))
      this.selectedIndex = activeIndex >= 0 ? activeIndex : 0
      this.updateSelection()
      this.optionTargets[this.selectedIndex]?.focus()
    })
  }

  close() {
    this.openValue = false
    this.buttonTarget.setAttribute('aria-expanded', 'false')
    this.selectedIndex = -1
    document.removeEventListener('click', this.boundHandleClickOutside)
  }

  handleClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  onButtonKeydown(event) {
    switch (event.key) {
      case 'Enter':
      case ' ':
      case 'ArrowDown':
        event.preventDefault()
        this.open()
        break
      case 'Escape':
        event.preventDefault()
        this.close()
        break
    }
  }

  onOptionKeydown(event) {
    const options = this.optionTargets

    switch (event.key) {
      case 'ArrowDown':
        event.preventDefault()
        this.selectedIndex = (this.selectedIndex + 1) % options.length
        this.updateSelection()
        options[this.selectedIndex]?.focus()
        break
      case 'ArrowUp':
        event.preventDefault()
        this.selectedIndex = (this.selectedIndex - 1 + options.length) % options.length
        this.updateSelection()
        options[this.selectedIndex]?.focus()
        break
      case 'Enter':
        // Let the link navigate naturally
        break
      case 'Escape':
        event.preventDefault()
        this.close()
        this.buttonTarget.focus()
        break
      case 'Tab':
        // Close dropdown on tab out
        this.close()
        break
    }
  }

  updateSelection() {
    this.optionTargets.forEach((option, index) => {
      if (index === this.selectedIndex) {
        option.classList.add('focused')
        option.setAttribute('tabindex', '0')
      } else {
        option.classList.remove('focused')
        option.setAttribute('tabindex', '-1')
      }
    })
  }

  openValueChanged() {
    if (this.openValue) {
      this.element.setAttribute('data-dropdown-open', '')
    } else {
      this.element.removeAttribute('data-dropdown-open')
    }
  }
}
