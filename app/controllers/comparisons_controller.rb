class ComparisonsController < ApplicationController
  MAX_TOOLS = 4

  # GET /compare?ids=2,5  (&add=10  or  &remove=5)
  # Stateless: the selected tools live entirely in the `ids` query param, so
  # comparisons are shareable by URL and need no session/account.
  def show
    ids = params[:ids].to_s.split(",").map(&:to_i)
    ids << params[:add].to_i if params[:add].present?
    ids.delete(params[:remove].to_i) if params[:remove].present?
    ids = ids.uniq.reject(&:zero?).first(MAX_TOOLS)

    by_id  = Tool.where(id: ids).index_by(&:id)
    @tools = ids.filter_map { |id| by_id[id] } # preserve the user's order

    if @tools.empty?
      redirect_to(root_path, alert: "Pick a tool to compare.") and return
    end

    @ids_param = @tools.map(&:id).join(",")
    @room      = @tools.size < MAX_TOOLS
    @addable   = Tool.visible.where.not(id: @tools.map(&:id)).order(:name) if @room
  end
end
