require "test_helper"

class PublicSiteTest < ActionDispatch::IntegrationTest
  test "home renders in Ukrainian by default with reports" do
    create_report(title: "Статут")

    get "/"

    assert_response :success
    assert_select "html[lang=uk]"
    assert_select "h1", /Сила жінки/
    assert_select ".docs a.doc-link", 1
    assert_select ".docs .doc", "Статут"
    assert_select ".docs .status", "PDF · 0,0 МБ"
    assert_includes response.body, "+380 96 119 50 47"
  end

  test "home shows a message when there are no reports" do
    get "/"

    assert_select ".docs .doc", "Документи готуються."
  end

  test "assets go through the pipeline with fingerprints" do
    get "/"

    assert_select "link[rel=stylesheet][href^='/assets/application-']"
    assert_select "script[type=importmap]"
  end

  test "?lang switches language and is remembered" do
    get "/?lang=en"
    assert_select "html[lang=en]"
    assert_select "h1", I18n.t("site.hero.title", locale: :en)

    get "/"
    assert_select "html[lang=en]"

    get "/?lang=uk"
    assert_select "html[lang=uk]"
  end

  test "browser language is used until a choice is saved" do
    get "/", headers: { "Accept-Language" => "en-GB,en;q=0.9" }
    assert_select "html[lang=en]"

    get "/?lang=uk", headers: { "Accept-Language" => "en-GB,en;q=0.9" }
    get "/", headers: { "Accept-Language" => "en-GB,en;q=0.9" }
    assert_select "html[lang=uk]"
  end

  test "unsupported languages fall through to the default" do
    get "/?lang=de", headers: { "Accept-Language" => "de-DE" }

    assert_select "html[lang=uk]"
    assert_nil cookies[:lang].presence
  end

  test "pages vary by language and aren't cached" do
    get "/"

    assert_includes response.headers["Vary"], "Cookie, Accept-Language"
    assert_includes response.headers["Cache-Control"], "no-cache"
  end

  test "news feed is newest first with a formatted date, gallery and Markdown" do
    NewsItem.create!(date: "2026-01-01", title_uk: "Старіша")
    newer = NewsItem.create!(date: "2026-10-20", title_uk: "Новіша", body_uk: "**текст**")
    create_image(newer, caption: "Перше")
    create_image(newer)

    get "/news"

    assert_response :success
    assert_select ".post h2 a", 2
    assert_select ".post:first-of-type h2 a[href=?]", "/news/#{newer.id}", "Новіша"
    assert_select ".post time[datetime='2026-10-20']", "20 жовтня 2026 р."
    assert_select ".post__body strong", "текст"
    assert_select ".slider figure", 2
    assert_select ".slider figcaption", 1
    assert_select ".slider__count", "1 / 2"
    assert_select ".slider img[alt=?]", "Новіша"
  end

  test "news without a translation is hidden in that language" do
    both = NewsItem.create!(date: "2026-01-02", title_uk: "Обидві", title_en: "Both")
    uk_only = NewsItem.create!(date: "2026-01-01", title_uk: "Лише UA", title_en: "")

    get "/news?lang=en"
    assert_select ".post h2 a", 1
    assert_select ".post h2 a", "Both"

    get "/news/#{uk_only.id}"
    assert_response :not_found
    assert_select ".feed__empty", /not found/

    get "/news/#{both.id}"
    assert_response :success
    assert_select "time", "2 January 2026"
  end

  test "empty feed and missing item have their own messages" do
    get "/news"
    assert_select ".feed__empty", "Новин поки немає."

    [ "/news/999", "/news/abc" ].each do |path|
      get path
      assert_response :not_found
      assert_select ".feed__empty", "Новину не знайдено."
    end
  end

  test "active storage direct uploads are closed" do
    post "/rails/active_storage/direct_uploads",
         params: { blob: { filename: "x.pdf", byte_size: 1, checksum: "x", content_type: "application/pdf" } }, as: :json

    assert_response :not_found
    assert_equal 0, ActiveStorage::Blob.count
  end

  test "uploaded files are publicly downloadable" do
    create_report

    get "/api/reports"
    get json.first["url"]
    follow_redirect!

    assert_response :success
    assert_equal "application/pdf", response.media_type
    assert_equal ApiTestHelpers::PDF_BYTES, response.body
  end
end
