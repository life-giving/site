module Api
  class NewsController < BaseController
    def index
      render json: NewsItem.feed.translated
    end

    def show
      render json: NewsItem.feed.translated.find(params[:id])
    end
  end
end
