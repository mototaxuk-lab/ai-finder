import { Controller } from "@hotwired/stimulus"

// Records a 👍/👎 on a result card via POST /events, then swaps the widget to
// a "thanks" state so it can't be double-submitted.
export default class extends Controller {
  static values = { tool: Number, query: String }
  static targets = ["prompt", "thanks"]

  up() { this.send("feedback_up") }
  down() { this.send("feedback_down") }

  send(eventType) {
    const token = document.querySelector('meta[name="csrf-token"]')?.content
    fetch("/events", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": token || ""
      },
      body: JSON.stringify({
        event_type: eventType,
        clicked_tool_id: this.toolValue,
        search_query: this.hasQueryValue ? this.queryValue : null
      }),
      keepalive: true
    }).catch(() => {})

    if (this.hasPromptTarget) this.promptTarget.hidden = true
    if (this.hasThanksTarget) this.thanksTarget.hidden = false
  }
}
