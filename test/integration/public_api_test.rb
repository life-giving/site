require "test_helper"

class PublicApiTest < ActionDispatch::IntegrationTest
  test "news is localised, newest first, with ordered images" do
    older = NewsItem.create!(date: "2026-01-01", title_uk: "Старіша")
    newer = NewsItem.create!(date: "2026-02-01", title_uk: "Новіша", body_uk: "**текст**")
    create_image(newer, caption: "Перше")
    create_image(newer)

    get "/api/news"

    assert_response :success
    assert_equal "application/json", response.media_type
    assert_equal [ newer.id, older.id ], json.pluck("id")
    first = json.first
    assert_equal "2026-02-01", first["date"]
    assert_equal "Новіша", first["title"]
    assert_equal "**текст**", first["body"]
    assert_equal [ "Перше", nil ], first["images"].pluck("caption")
    assert_match %r{\A/rails/active_storage/blobs/}, first["images"].first["url"]
  end

  test "news follows ?lang and hides untranslated items" do
    both = NewsItem.create!(date: "2026-01-02", title_uk: "Обидві", title_en: "Both")
    uk_only = NewsItem.create!(date: "2026-01-01", title_uk: "Лише UA")

    get "/api/news?lang=en"
    assert_equal [ "Both" ], json.pluck("title")

    get "/api/news/#{both.id}"
    assert_equal "Both", json["title"]

    get "/api/news/#{uk_only.id}"
    assert_response :not_found
    assert_equal "application/json", response.media_type
  end

  test "reports are in position order, with the title falling back to Ukrainian" do
    first = create_report(title: "Перший")
    second = create_report(title: "Другий")
    second.move_to(0)

    get "/api/reports?lang=en"

    assert_response :success
    assert_equal [ second.id, first.id ], json.pluck("id")
    assert_equal "Другий", json.first["title"]
    assert_equal ApiTestHelpers::PDF_BYTES.bytesize, json.first["byte_size"]
    assert_match %r{/report\.pdf\z}, json.first["url"]
  end

  test "the admin JSON API is gone" do
    create_admin

    [ "/api/admin/news", "/api/admin/reports", "/api/admin/session" ].each do |path|
      get path
      assert_response :not_found
    end
  end
end
