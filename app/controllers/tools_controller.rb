class ToolsController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound do
    redirect_to root_path, alert: "We couldn't find that tool."
  end

  def show
    @tool = Tool.find(params[:id])
    Event.record(event_type: "specs_expand", clicked_tool_id: @tool.id)

    # For the "Compare with…" picker: same-category tools first, then the rest.
    @similar_tools = Tool.visible
                         .joins(:categories)
                         .where(categories: { id: @tool.category_ids })
                         .where.not(id: @tool.id)
                         .distinct.order(:name)
    @other_tools = Tool.visible
                       .where.not(id: [@tool.id, *@similar_tools.map(&:id)])
                       .order(:name)
  end
end
