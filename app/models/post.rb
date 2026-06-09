class Post < ApplicationRecord
  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true

  # Published = has a publish date that's in the past (nil published_at = draft).
  scope :published, -> { where.not(published_at: nil).where("published_at <= ?", Time.current) }
  scope :recent,    -> { order(published_at: :desc) }

  # Pretty URLs: /blog/<slug>
  def to_param = slug
end
