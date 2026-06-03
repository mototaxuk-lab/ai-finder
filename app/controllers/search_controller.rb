class SearchController < ApplicationController
  def index
    @query = params[:q].to_s.strip

    @need =
      if params[:category].present?
        # Browse tile: already structured, skip the parser (and, later, the LLM).
        ParsedNeed.from_category(params[:category])
      elsif @query.present?
        # Step 5 will swap this for NeedParser.call(@query) (LLM + this as fallback).
        ParsedNeed.from_keywords(@query)
      end

    return redirect_to(root_path) if @need.nil?

    @result = ToolMatcher.call(@need)
    @tools  = @result.tools

    # Step 8: log a `search` event (query, parsed filters, shown tool ids) here.
  end
end
