import { Controller } from '@hotwired/stimulus'
import consumer from 'consumer'

export default class extends Controller {
  static targets = ['value']

  static values = {
    seriesOptions: Object
  }

  connect () {
    const controller = this
    consumer.subscriptions.create({ channel: 'RailsObservatory::ChartChannel', series: this.seriesOptionsValue }, {
      connected () {
        this.perform('init')
      },
      received (data) {
        controller.update(data)
      }
    })
  }

  // Format number with commas and K suffix
  formatNumber (number) {
    return Intl.NumberFormat('en', { notation: 'compact' }).format(number)
  }

  update (data) {
    if (data.length === 0) return
    const sum = data[0].data.reduce((acc, val) => acc + val[1], 0)
    this.valueTarget.innerText = `${this.formatNumber(sum)}`
  }

}