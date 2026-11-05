require "test_helper"

class AdminContentTest < ActionDispatch::IntegrationTest
  FRAME = { "Turbo-Frame" => "gallery" }.freeze

  setup { log_in }

  def pdf = upload(PDF_BYTES, "report.pdf", "application/pdf")
  def png = upload(PNG_BYTES, "photo.png", "image/png")
  def news_item = NewsItem.create!(date: "2026-03-01", title_uk: "Новина")

  test "news create, update, delete" do
    post "/admin/news", params: { news_item: { date: "2026-03-01", title_uk: "Заголовок", body_uk: "# Текст" } }
    item = NewsItem.last
    assert_redirected_to "/admin/news/#{item.id}/edit"
    follow_redirect!
    assert_select ".admin-alert--ok", "Збережено."
    assert_select "#preview_uk h1", "Текст"

    patch "/admin/news/#{item.id}", params: { news_item: { title_en: "Title" } }
    assert_equal "Title", item.reload.title_en

    delete "/admin/news/#{item.id}"
    assert_redirected_to "/admin/news"
    assert_not NewsItem.exists?(item.id)
  end

  test "news form has both languages and starts on today's date" do
    get "/admin/news/new"

    assert_response :success
    assert_select "input[name='news_item[date]'][value=?]", Date.current.iso8601
    assert_select "input[name='news_item[title_uk]']"
    assert_select "input[name='news_item[title_en]']"
    assert_select "[data-language=en][hidden]"
  end

  test "news needs a date and a Ukrainian title, with errors in Ukrainian" do
    post "/admin/news", params: { news_item: { title_en: "Title" } }

    assert_response :unprocessable_content
    assert_select ".admin-alert", /Дата/
    assert_select ".admin-alert", /Заголовок \(UA\)/
    assert_equal 0, NewsItem.count
  end

  test "preview renders on the server through a Turbo Stream" do
    post "/admin/news/preview", params: { language: "en", body: "**x** [bad](javascript:alert(1))" }

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_includes response.body, %(target="preview_en")
    assert_includes response.body, "<strong>x</strong>"
    assert_not_includes response.body, "javascript:"

    post "/admin/news/preview", params: { language: "de", body: "x" }
    assert_response :bad_request
  end

  test "gallery upload of several files, caption, reorder, delete" do
    item = news_item

    post "/admin/news/#{item.id}/images", params: { files: [ png, png ] }
    assert_redirected_to "/admin/news/#{item.id}/edit"
    first, second = item.images.reload.to_a
    assert_equal 2, item.images.size

    patch "/admin/news/#{item.id}/images/#{first.id}", params: { caption: "Перше" }
    patch "/admin/news/#{item.id}/images/#{second.id}", params: { position: 0 }
    assert_equal [ second, first ], item.images.reload.to_a
    assert_equal "Перше", first.reload.caption

    delete "/admin/news/#{item.id}/images/#{second.id}"
    assert_equal [ first ], item.images.reload.to_a

    get "/admin/news/#{item.id}/edit"
    assert_select "turbo-frame#gallery .admin-thumb", 1
  end

  test "an image can only be reached through its own news item" do
    image = create_image(news_item)
    other = news_item

    delete "/admin/news/#{other.id}/images/#{image.id}"

    assert_response :not_found
    assert NewsImage.exists?(image.id)
  end

  test "report upload, retitle, reorder, delete" do
    post "/admin/reports", params: { report: { file: pdf, title_uk: "Звіт 2025", title_en: "Report 2025" } }
    assert_redirected_to "/admin/reports"
    report = Report.last
    assert_equal "Report 2025", report.title_en

    other = create_report

    patch "/admin/reports/#{other.id}", params: { position: 0 }
    assert_equal [ other.id, report.id ], Report.ordered.ids

    patch "/admin/reports/#{report.id}", params: { report: { title_uk: "Звіт за 2025" } }
    assert_equal "Звіт за 2025", report.reload.title_uk

    get "/admin/reports"
    assert_select ".admin-item", 2

    delete "/admin/reports/#{report.id}"
    assert_redirected_to "/admin/reports"
    assert_not Report.exists?(report.id)
  end

  test "report needs a file, and a string is not accepted as one" do
    post "/admin/reports", params: { report: { title_uk: "Звіт" } }
    assert_response :unprocessable_content
    assert_select ".admin-alert", /Файл/

    post "/admin/reports", params: { report: { title_uk: "Звіт", file: "signed-id" } }
    assert_response :unprocessable_content
    assert_equal 0, Report.count
  end

  test "file renamed to .pdf is rejected whatever type the client claims" do
    post "/admin/reports", params: { report: { title_uk: "Звіт", file: upload("just text, not a pdf", "report.pdf", "application/pdf") } }

    assert_response :unprocessable_content
    assert_select ".admin-alert", /недопустимий тип файлу/
    assert_equal 0, Report.count
  end

  test "pdf disguised as an image is rejected inside the gallery frame" do
    item = news_item

    post "/admin/news/#{item.id}/images", params: { files: [ upload(PDF_BYTES, "photo.png", "image/png") ] }, headers: FRAME

    assert_response :unprocessable_content
    assert_select "turbo-frame#gallery .admin-alert", /недопустимий тип файлу/
    assert_equal 0, item.images.count
  end

  test "svg images are rejected" do
    item = news_item

    post "/admin/news/#{item.id}/images", params: { files: [ upload(SVG_BYTES, "logo.svg", "image/svg+xml") ] }, headers: FRAME

    assert_response :unprocessable_content
    assert_equal 0, item.images.count
  end

  test "submitting the gallery with no file shows an error" do
    item = news_item

    post "/admin/news/#{item.id}/images", headers: FRAME

    assert_response :unprocessable_content
    assert_select "turbo-frame#gallery .admin-alert"
  end

  test "oversized pdf is rejected at the configured limit" do
    with_upload_limit(:max_pdf_size_mb, 1) do
      post "/admin/reports", params: { report: { title_uk: "Звіт", file: upload(PDF_BYTES + "0" * (1.megabyte + 1), "big.pdf", "application/pdf") } }

      assert_response :content_too_large
      assert_select ".admin-alert", /1 МБ/
      assert_equal 0, Report.count
    end
  end

  test "oversized image is rejected at the configured limit" do
    item = news_item

    with_upload_limit(:max_image_size_mb, 1) do
      post "/admin/news/#{item.id}/images", params: { files: [ upload(PNG_BYTES + "0" * (1.megabyte + 1), "big.png", "image/png") ] }

      assert_response :content_too_large
      assert_equal 0, item.images.count
    end
  end

  test "request far over the limit is stopped by Content-Length" do
    with_upload_limit(:max_pdf_size_mb, 1) do
      post "/admin/reports", params: { report: { title_uk: "Звіт", file: upload(PDF_BYTES + "0" * 3.megabytes, "big.pdf", "application/pdf") } }

      assert_redirected_to "/admin/reports"
      assert_equal 0, ActiveStorage::Blob.count
      follow_redirect!
      assert_select ".admin-alert", /1 МБ/
    end
  end

  test "editing a report survives a lowered limit" do
    report = Report.create!(title_uk: "Звіт", file: { io: StringIO.new(PDF_BYTES + "0" * (1.megabyte + 1)), filename: "big.pdf" })

    with_upload_limit(:max_pdf_size_mb, 1) do
      patch "/admin/reports/#{report.id}", params: { report: { title_uk: "Новий" } }
      assert_redirected_to "/admin/reports"
      assert_equal "Новий", report.reload.title_uk
    end
  end
end
