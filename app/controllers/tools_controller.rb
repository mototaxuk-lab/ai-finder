class ToolsController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound do
    redirect_to root_path, alert: "We couldn't find that tool."
  end

  def show
    @tool = Tool.find(params[:id])
  end
end
