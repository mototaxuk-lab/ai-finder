class Category < ApplicationRecord
  has_many :tool_categories, dependent: :destroy
  has_many :tools, through: :tool_categories

  validates :slug, presence: true, uniqueness: true
  validates :display_name, presence: true

  scope :ordered, -> { order(:position, :display_name) }
end
