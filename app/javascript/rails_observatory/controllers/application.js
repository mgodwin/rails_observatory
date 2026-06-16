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

const reloadFrame = (frame) => {
  if (typeof frame.reload === "function") {
    frame.reload()
  } else {
    // Older Turbo: re-assigning src forces a re-fetch.
    const src = frame.getAttribute("src")
    if (src) {
      frame.removeAttribute("src")
      frame.setAttribute("src", src)
    }
  }
}

addEventListener("turbo:fetch-request-error", (event) => {
  const frame = event.target instanceof Element ? event.target.closest("turbo-frame") : null

  // A turbo-frame failed to load (e.g. the server is briefly down). Reloading
  // the whole page here is jarring and can spiral into a reload loop while the
  // server is unreachable. Keep the frame in its loading state and retry with
  // backoff so it recovers on its own once the server is back.
  if (frame) {
    event.preventDefault()

    // Turbo clears the busy attribute in the request's `finally` block, which
    // runs right after this event, so re-apply it on the next tick to keep the
    // spinner visible until the retry kicks in.
    queueMicrotask(() => {
      frame.setAttribute("busy", "")
      frame.setAttribute("aria-busy", "true")
    })

    const attempts = Number(frame.dataset.reloadAttempts || 0) + 1
    frame.dataset.reloadAttempts = String(attempts)
    const delay = Math.min(1000 * 2 ** (attempts - 1), 30000)
    setTimeout(() => reloadFrame(frame), delay)
    return
  }

  // Full-page navigation failed — reload to surface / recover from the error.
  console.log("Turbo fetch request error:", event.detail.request, event.detail.error);
  window.location.reload()
})

// Reset the retry backoff once a frame loads successfully.
addEventListener("turbo:frame-load", (event) => {
  delete event.target.dataset.reloadAttempts
})

export { application }