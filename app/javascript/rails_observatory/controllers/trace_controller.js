import { Controller } from '@hotwired/stimulus'

export default class extends Controller {

  showEventDetails (event) {
    console.log('showEventDetails', event)

  }
}