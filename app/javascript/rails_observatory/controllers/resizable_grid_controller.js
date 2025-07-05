import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  connect () {
    this.boundResize = this.resize.bind(this)
    this.boundEndResize = this.endResize.bind(this)
  }

  startResizeY (event) {
    this.dragStartY = event.pageY
    this.row = event.currentTarget.parentElement.previousElementSibling
    this.rowStartHeight = this.row.clientHeight
    document.body.style.userSelect = 'none'
    window.addEventListener('mousemove', this.boundResize)
    window.addEventListener('mouseup', this.boundEndResize)
  }

  resize (event) {
    this.dragY = event.pageY
    const delta = this.dragY - this.dragStartY
    const newSize = this.rowStartHeight + delta
    if (newSize < 80) return
    this.row.style.height = `${newSize}px`
  }

  endResize () {
    document.body.style.removeProperty('user-select')
    window.removeEventListener('mousemove', this.boundResize)
    window.removeEventListener('mouseup', this.boundEndResize)
  }
}