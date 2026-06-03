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

    # Step 8: log a `search` event (query, parsed filters, shown tool ids) here.
  end
end
