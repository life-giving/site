class NewsItem < ApplicationRecord
  has_many :images, -> { ordered }, class_name: "NewsImage", inverse_of: :news_item, dependent: :destroy

  normalizes :title_uk, :title_en, with: ->(title) { title.strip.presence }

  validates :date, :title_uk, presence: true

  scope :feed, -> { includes(images: { file_attachment: :blob }).order(date: :desc, id: :desc) }
  # An item with no title in the current language isn't shown in that language.
  scope :translated, -> { I18n.locale == :en ? where.not(title_en: [ nil, "" ]) : all }

  def title
    self["title_#{I18n.locale}"]
  end

  def body
    self["body_#{I18n.locale}"]
  end

  def as_json(*)
    { id: id, date: date, title: title, body: body, images: images }
  end
end
