import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['column', 'resizeHandle', 'pagination']

  setProperties () {
    const templateCols = []
    for (let i = 0; i < this.getColumnCount(); i++) {
      templateCols.push(`var(--column-${i}, auto)`)
    }
    this.element.style.gridTemplateColumns = templateCols.join(' ')
  }

  getColumnCount () {
    return window.getComputedStyle(this.element).getPropertyValue('--column-count')
  }

  connect () {
    this.setProperties()
    this.initializeFromLocalStorage()
  }

  initializeFromLocalStorage () {
    if (!this.element.id) return
    const stored = localStorage.getItem(`grid-table-${this.element.id}`)
    if (stored) {
      const columnProperties = stored.split(',')
      for (let i = 0; i < columnProperties.length; i++) {
        this.updateColumnWidth(i, columnProperties[i])
      }
    }
  }

  saveToLocalStorage () {
    if (!this.element.id) return
    localStorage.setItem(`grid-table-${this.element.id}`, this.getColumnProperties().join())
  }

  getColumnProperties () {
    const columnProperties = []
    for (let i = 0; i < this.getColumnCount(); i++) {
      columnProperties.push(this.getColumnProperty(i))
    }
    return columnProperties
  }

  getColumnProperty (index) {
    return window.getComputedStyle(this.element).getPropertyValue(`--column-${index}`)
  }

  updateColumnWidth (index, width) {
    this.element.style.setProperty(`--column-${index}`, width)
  }

  getHandleIndex (handleElement) {
    return this.resizeHandleTargets.indexOf(handleElement) - 1
  }

  resizeMin (event) {
    this.updateColumnWidth(this.getHandleIndex(event.target), 'min-content')
    this.saveToLocalStorage()
  }

  startResize (event) {
    const handleIndex = this.getHandleIndex(event.target)
    const column = this.columnTargets[handleIndex]
    this.columnWidth = column.offsetWidth
    this.columnDragIndex = handleIndex
    this.dragStartX = event.pageX
    this.boundResize = this.resize.bind(this)
    this.boundEndResize = this.endResize.bind(this)
    document.body.style.userSelect = 'none'
    window.addEventListener('mousemove', this.boundResize)
    window.addEventListener('mouseup', this.boundEndResize)
  }

  resize (event) {
    this.dragX = event.pageX
    const delta = this.dragX - this.dragStartX
    const newWidth = this.columnWidth + delta
    if (newWidth < 50) return
    this.updateColumnWidth(this.columnDragIndex, `${newWidth}px`)
  }

  endResize () {
    document.body.style.removeProperty('user-select')
    window.removeEventListener('mousemove', this.boundResize)
    window.removeEventListener('mouseup', this.boundEndResize)
    this.saveToLocalStorage()
  }

  goToPage (event) {
    const page = event.currentTarget.dataset.page
    if (!page) return

    const turboFrame = this.element.closest('turbo-frame')
    if (turboFrame) {
      const currentSrc = turboFrame.getAttribute('src') || window.location.href
      const url = new URL(currentSrc, window.location.origin)
      url.searchParams.set('page', page)
      turboFrame.setAttribute('src', url.toString())
    }
  }
}