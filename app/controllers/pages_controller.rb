class PagesController < ApplicationController
  def home
    @categories = Category.ordered
    @recent_posts = Post.published.recent.limit(3)
  end
end
