class NewsImage < ApplicationRecord
  include Positioned

  EXTENSIONS = { "image/jpeg" => "jpg", "image/png" => "png", "image/webp" => "webp" }.freeze

  belongs_to :news_item
  has_one_attached :file, dependent: :purge

  validates :file, attachment: { kind: :image }

  before_save :use_neutral_filename

  def siblings
    news_item.images.unscope(:order)
  end

  def as_json(*)
    {
      id: id,
      url: Rails.application.routes.url_helpers.rails_blob_path(file, only_path: true),
      caption: caption
    }
  end

  private

  # Filenames appear in public URLs, and a name like "olena-shelter.jpg" could identify someone.
  def use_neutral_filename
    return unless attachment_changes.key?("file")

    file.blob.filename = "photo-#{SecureRandom.hex(8)}.#{EXTENSIONS.fetch(file.blob.content_type)}"
  end
end
