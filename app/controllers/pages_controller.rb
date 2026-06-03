class PagesController < ApplicationController
  def home
    @categories = Category.ordered
  end
end
