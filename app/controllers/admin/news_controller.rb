module Admin
  class NewsController < BaseController
    before_action :set_item, only: %i[edit update destroy]

    def index
      @items = NewsItem.feed
    end

    def new
      @item = NewsItem.new(date: Date.current)
    end

    def create
      @item = NewsItem.new(item_params)
      if @item.save
        redirect_to edit_admin_news_path(@item), notice: t("admin.saved"), status: :see_other
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit
    end

    def update
      if @item.update(item_params)
        redirect_to edit_admin_news_path(@item), notice: t("admin.saved"), status: :see_other
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @item.destroy!
      redirect_to admin_news_index_path, notice: t("admin.deleted"), status: :see_other
    end

    def preview
      language = %w[uk en].find { |code| code == params[:language] }
      return head :bad_request unless language

      render turbo_stream: turbo_stream.update("preview_#{language}", MarkdownRenderer.render(params[:body]))
    end

    private

    def set_item
      @item = NewsItem.feed.find(params[:id])
    end

    def item_params
      params.expect(news_item: %i[date title_uk title_en body_uk body_en])
    end
  end
end
