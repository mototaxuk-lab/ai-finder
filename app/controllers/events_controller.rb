class EventsController < ApplicationController
  ALLOWED_TYPES = %w[card_click specs_expand search].freeze

  # Lightweight client-side logging (e.g. an outbound "Visit site" click).
  # Always returns 204 — a logging failure must never surface to the user.
  def create
    type = params[:event_type].to_s
    if ALLOWED_TYPES.include?(type)
      Event.record(
        event_type:      type,
        search_query:    params[:search_query].presence,
        clicked_tool_id: params[:clicked_tool_id].presence
      )
    end
    head :no_content
  end
end
