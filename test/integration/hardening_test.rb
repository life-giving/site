require "test_helper"

class HardeningTest < ActionDispatch::IntegrationTest
  FRAME = { "Turbo-Frame" => "gallery" }.freeze

  def photo(size, name = "photo.png") = upload(PNG_BYTES + "0" * size, name, "image/png")
  def news_item = NewsItem.create!(date: "2026-03-01", title_uk: "Новина")

  test "several photos may exceed the single-file limit together" do
    log_in
    item = news_item

    with_upload_limit(:max_image_size_mb, 1) do
      post "/admin/news/#{item.id}/images", params: { files: Array.new(3) { photo(800.kilobytes) } }
    end

    assert_redirected_to "/admin/news/#{item.id}/edit"
    assert_equal 3, item.images.count
  end

  test "too many photos at once are refused" do
    log_in
    item = news_item

    with_upload_limit(:max_images_per_upload, 2) do
      post "/admin/news/#{item.id}/images", params: { files: Array.new(3) { png_file } }
    end

    assert_response :unprocessable_content
    assert_equal 0, item.images.count
  end

  test "a batch with one bad file saves nothing and names that file" do
    log_in
    item = news_item

    post "/admin/news/#{item.id}/images", params: { files: [ png_file, upload("not an image", "broken.png", "image/png"), png_file ] }, headers: FRAME

    assert_response :unprocessable_content
    assert_equal 0, item.images.count
    assert_equal 0, ActiveStorage::Blob.count
    assert_select "turbo-frame#gallery .admin-alert", /broken\.png/
  end

  test "gallery files lose their original names" do
    log_in
    item = news_item

    post "/admin/news/#{item.id}/images", params: { files: [ upload(PNG_BYTES, "olena-shelter.png", "image/png") ] }

    get "/api/news/#{item.id}"
    assert_not_includes response.body, "olena"
    assert_match %r{/photo-[0-9a-f]+\.png\z}, json["images"].first["url"]
  end

  test "error pages show the hotline in the visitor's language" do
    { "/404" => 404, "/422" => 422, "/500" => 500 }.each do |path, status|
      get path
      assert_response status
      assert_select "html[lang=uk]"
      assert_includes response.body, "+380 96 119 50 47"
      assert_includes response.body, I18n.t("site.hero.emergency", locale: :uk)
    end

    get "/404?lang=en"
    assert_select "html[lang=en]"
  end

  test "public pages set no cookies and use no third-party hosts" do
    %w[/ /news].each do |path|
      get path
      assert_response :success
      assert_nil response.headers["Set-Cookie"], path
      assert_no_match %r{(?:href|src)="https?://(?!www\.instagram\.com|www\.facebook\.com)}, response.body, path
      assert_not_includes response.body, "fonts.g"
    end
  end

  test "changing a password ends existing sessions" do
    admin = log_in
    get "/admin/news"
    assert_response :success

    admin.update!(password: "a-brand-new-password")

    get "/admin/news"
    assert_redirected_to "/admin/session/new"
  end

  test "login attempts are limited per email across addresses" do
    11.times do |i|
      post "/admin/session", params: { email: "Target@example.org ", password: "wrong" }, headers: { "REMOTE_ADDR" => "10.0.0.#{i + 1}" }
    end

    assert_response :too_many_requests
  end

  test "a saved flash shows once" do
    log_in
    item = news_item

    patch "/admin/news/#{item.id}", params: { news_item: { title_en: "Title" } }
    follow_redirect!

    assert_select ".admin-alert--ok", 1
  end

  test "pages send a content security policy" do
    get "/"

    policy = response.headers["Content-Security-Policy"]
    assert_includes policy, "default-src 'self'"
    assert_includes policy, "frame-ancestors 'none'"
    assert_match(/script-src 'self' 'nonce-/, policy)
    assert_select "meta[name=csp-nonce]"
  end

  test "later browser languages are considered, in q order" do
    get "/", headers: { "Accept-Language" => "fr,en;q=0.9" }
    assert_select "html[lang=en]"

    get "/", headers: { "Accept-Language" => "en;q=0.5,uk;q=0.9" }
    assert_select "html[lang=uk]"
  end

  test "a language the browser refuses is skipped" do
    get "/", headers: { "Accept-Language" => "en;q=0,fr" }
    assert_select "html[lang=uk]"
  end

  test "a whitespace title doesn't count as a translation" do
    item = NewsItem.create!(date: "2026-03-01", title_uk: " Новина ", title_en: "   ")

    assert_equal "Новина", item.title_uk
    assert_nil item.title_en
    get "/news?lang=en"
    assert_select ".post", 0
  end

  private

  def png_file = upload(PNG_BYTES, "photo.png", "image/png")
end
