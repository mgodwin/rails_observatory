import { Application } from "@hotwired/stimulus"

const application = Application.start()

// Configure Stimulus development experience
application.debug = true
window.Stimulus   = application

addEventListener("turbo:before-frame-render", (event) => {
  if (document.startViewTransition) {
    const originalRender = event.detail.render;
    event.detail.render = (currentElement, newElement) => {
      document.startViewTransition(() => originalRender(currentElement, newElement));
    };
  }
});

addEventListener("turbo:fetch-request-error", (event) => {
  console.log("Turbo fetch request error:", event.detail.request, event.detail.error);
  window.location.reload()
})

export { application }