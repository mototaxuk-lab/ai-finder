class SearchController < ApplicationController
  def index
    @query = params[:q].to_s.strip

    @need =
      if params[:category].present?
        # Browse tile: already structured, skip the parser (and, later, the LLM).
        ParsedNeed.from_category(params[:category])
      elsif @query.present?
        # LLM parse (Claude Haiku); falls back to keyword parse on any failure.
        NeedParser.call(@query)
      end

    return redirect_to(root_path) if @need.nil?

    @result = ToolMatcher.call(@need)
    @tools  = @result.tools

    Event.record(
      event_type:     "search",
      search_query:   @query.presence,
      parsed_filters: @need.to_h,
      shown_tool_ids: @tools.map(&:id)
    )
  end
end
