import { Controller } from "@hotwired/stimulus"

// Fires a fire-and-forget POST /events when the element is clicked.
// Used on outbound "Visit site" links to record a card_click conversion.
export default class extends Controller {
  static values = { type: String, tool: Number }

  log() {
    const token = document.querySelector('meta[name="csrf-token"]')?.content
    fetch("/events", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": token || ""
      },
      body: JSON.stringify({
        event_type: this.typeValue,
        clicked_tool_id: this.hasToolValue ? this.toolValue : null
      }),
      keepalive: true // completes even as the browser navigates away
    }).catch(() => {})
  }
}
