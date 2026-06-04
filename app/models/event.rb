class Event < ApplicationRecord
  # created_at only (no updated_at on this table).
  self.record_timestamps = true

  enum :event_type,
       { search: "search", card_click: "card_click", specs_expand: "specs_expand" },
       prefix: :event

  belongs_to :clicked_tool, class_name: "Tool", foreign_key: :clicked_tool_id, optional: true

  validates :event_type, presence: true

  # Fire-and-forget logging. Analytics must never break a user-facing request,
  # so swallow and log any failure rather than raising.
  def self.record(event_type:, search_query: nil, parsed_filters: {}, shown_tool_ids: [], clicked_tool_id: nil)
    create!(
      event_type:      event_type,
      search_query:    search_query,
      parsed_filters:  parsed_filters || {},
      shown_tool_ids:  shown_tool_ids || [],
      clicked_tool_id: clicked_tool_id
    )
  rescue => e
    Rails.logger.warn("[Event] failed to record #{event_type}: #{e.class}: #{e.message}")
    nil
  end
end

