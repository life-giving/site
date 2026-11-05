class NewsController < ApplicationController
  def index
    @items = NewsItem.feed.translated
  end

  def show
    @item = NewsItem.feed.translated.find_by(id: params[:id])
    render :missing, status: :not_found unless @item
  end
end
