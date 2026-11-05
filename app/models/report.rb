class Report < ApplicationRecord
  include Positioned

  has_one_attached :file, dependent: :purge

  normalizes :title_uk, :title_en, with: ->(title) { title.strip.presence }

  validates :title_uk, presence: true
  validates :file, attachment: { kind: :pdf }

  scope :listed, -> { with_attached_file.ordered }

  def siblings
    self.class.all
  end

  # A document matters more than the language of its label, so it falls back to Ukrainian.
  def title
    self["title_#{I18n.locale}"].presence || title_uk
  end

  def as_json(*)
    {
      id: id,
      title: title,
      url: Rails.application.routes.url_helpers.rails_blob_path(file, only_path: true),
      byte_size: file.blob.byte_size
    }
  end
end
