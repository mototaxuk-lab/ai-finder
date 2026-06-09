class ReviewsController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound do
    redirect_to root_path, alert: "That review isn't available."
  end

  def show
    @review = Review.published.find_by!(slug: params[:id])
    @tool   = @review.tool
  end
end
