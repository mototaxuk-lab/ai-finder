class ToolsController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound do
    redirect_to root_path, alert: "We couldn't find that tool."
  end

  def show
    @tool = Tool.find(params[:id])
    Event.record(event_type: "specs_expand", clicked_tool_id: @tool.id)
  end
end
