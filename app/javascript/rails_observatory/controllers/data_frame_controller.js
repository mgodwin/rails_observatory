import {Controller} from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["value", "data"]

  navigate(event) {
    const href = event.target.dataset.href
    if (href) {
      const url = new URL(href, window.location.href)
      url.searchParams.set('variant', this.element.id)
      fetch(url.toString())
        .then(response => response.text())
        .then(html => {
          const frag = new DOMParser().parseFromString(html, 'text/html')
          console.log(frag)
          this.element.outerHTML = html
        })
    } else {
      throw new Error('cannot navigate without data-href')
    }
  }

}