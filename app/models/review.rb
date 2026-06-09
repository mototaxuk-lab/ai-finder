class Review < ApplicationRecord
  belongs_to :tool

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :rating, inclusion: { in: 1..5 }, allow_nil: true

  scope :published, -> { where.not(published_at: nil).where("published_at <= ?", Time.current) }
  scope :recent,    -> { order(published_at: :desc) }

  def to_param = slug

  def published?
    published_at.present? && published_at <= Time.current
  end
end
