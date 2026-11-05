module Admin
  # Runs inside the gallery's Turbo Frame, so these actions never touch unsaved editor text.
  class ImagesController < BaseController
    before_action :set_item
    before_action :limit_upload_request, only: :create
    before_action :set_image, only: %i[update destroy]

    def create
      files = Array(params[:files]).select { |file| file.respond_to?(:read) }
      return render_failure(@item.images.new.tap(&:validate).errors.full_messages, :unprocessable_content) if files.empty?

      if files.size > upload_limit(:max_images_per_upload)
        message = t("admin.too_many_files", max_files: upload_limit(:max_images_per_upload))
        return render_failure([ message ], :unprocessable_content)
      end

      save_batch(files.map { |file| @item.images.new(file: file) })
    end

    def update
      @image.update!(params.permit(:caption))
      @image.move_to(params[:position]) if params.key?(:position)
      redirect_to_editor
    end

    def destroy
      @image.destroy!
      redirect_to_editor
    end

    private

    def set_item
      @item = NewsItem.feed.find(params[:news_id])
    end

    def set_image
      @image = @item.images.find(params[:id])
    end

    def limit_upload_request
      limit_request_body(:max_image_size_mb, edit_admin_news_path(@item), files: upload_limit(:max_images_per_upload))
    end

    # All or nothing: otherwise retrying after one bad file would duplicate the good ones.
    def save_batch(images)
      failed = images.reject(&:valid?)
      return render_rejected(failed) if failed.any?

      NewsImage.transaction { images.each(&:save!) }
      redirect_to_editor
    end

    def render_rejected(images)
      messages = images.map { |image| "«#{image.file.filename}»: #{image.errors.full_messages.to_sentence}" }
      render_failure(messages, images.any? { |image| error_status(image) == :content_too_large } ? :content_too_large : :unprocessable_content)
    end

    def redirect_to_editor
      redirect_to edit_admin_news_path(@item), status: :see_other
    end

    def render_failure(messages, status)
      flash.now[:alert] = messages.join("\n")
      render partial: "admin/news/gallery", locals: { item: NewsItem.feed.find(@item.id) }, status: status
    end
  end
end
