class ToolCategory < ApplicationRecord
  belongs_to :tool
  belongs_to :category

  validates :tool_id, uniqueness: { scope: :category_id }
end
