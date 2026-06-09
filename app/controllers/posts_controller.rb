class PostsController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound do
    redirect_to posts_path, alert: "That post isn't available."
  end

  def index
    @posts = Post.published.recent
  end

  def show
    @post = Post.published.find_by!(slug: params[:id])
  end
end
