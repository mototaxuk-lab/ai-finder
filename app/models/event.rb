class Event < ApplicationRecord
  # created_at only (no updated_at on this table).
  self.record_timestamps = true

  enum :event_type,
       { search: "search", card_click: "card_click", specs_expand: "specs_expand" },
       prefix: :event

  belongs_to :clicked_tool, class_name: "Tool", foreign_key: :clicked_tool_id, optional: true

  validates :event_type, presence: true
end
