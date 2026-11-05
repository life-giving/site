require "test_helper"

class AdminAuthTest < ActionDispatch::IntegrationTest
  PROTECTED = [
    [ :get, "/admin/news" ],
    [ :get, "/admin/news/new" ],
    [ :post, "/admin/news" ],
    [ :post, "/admin/news/preview" ],
    [ :get, "/admin/news/1/edit" ],
    [ :patch, "/admin/news/1" ],
    [ :delete, "/admin/news/1" ],
    [ :post, "/admin/news/1/images" ],
    [ :patch, "/admin/news/1/images/1" ],
    [ :delete, "/admin/news/1/images/1" ],
    [ :get, "/admin/reports" ],
    [ :post, "/admin/reports" ],
    [ :patch, "/admin/reports/1" ],
    [ :delete, "/admin/reports/1" ]
  ].freeze

  def forged_token(admin, claims: {}, key: "x" * 32, algorithm: "HS256")
    JWT.encode({ sub: admin.id.to_s, exp: 1.hour.from_now.to_i }.merge(claims), key, algorithm)
  end

  test "every admin page sends visitors without a session to login" do
    PROTECTED.each do |verb, path|
      public_send(verb, path)
      assert_redirected_to "/admin/session/new", "#{verb} #{path}"
    end
  end

  test "/admin leads to the news list" do
    get "/admin"
    assert_redirected_to "/admin/news"
  end

  test "login sets a locked-down cookie and logout clears it" do
    log_in

    cookie = Array(response.headers["Set-Cookie"]).join("\n")
    assert_match(/admin_token=/, cookie)
    assert_match(/httponly/i, cookie)
    assert_match(/samesite=strict/i, cookie)
    assert_match(%r{path=/admin}i, cookie)

    get "/admin/news"
    assert_response :success
    assert_select ".admin-nav__user", "admin@example.org"

    delete "/admin/session"
    assert_redirected_to "/admin/session/new"
    get "/admin/news"
    assert_redirected_to "/admin/session/new"
  end

  test "wrong password and unknown email look the same" do
    admin = create_admin

    post "/admin/session", params: { email: admin.email, password: "wrong" }
    assert_response :unprocessable_content
    assert_select ".admin-alert", "Неправильний email або пароль."

    post "/admin/session", params: { email: "nobody@example.org", password: "wrong" }
    assert_response :unprocessable_content
    assert_select ".admin-alert", "Неправильний email або пароль."
    get "/admin/news"
    assert_redirected_to "/admin/session/new"
  end

  test "login is rate limited" do
    5.times do
      post "/admin/session", params: { email: "a@example.org", password: "wrong" }
      assert_response :unprocessable_content
    end

    post "/admin/session", params: { email: "a@example.org", password: "wrong" }
    assert_response :too_many_requests
    assert_select ".admin-alert", /Забагато спроб/
  end

  test "tampered, wrongly signed, expired and orphaned tokens are rejected" do
    admin = create_admin
    good = JwtToken.encode(admin)
    tokens = {
      tampered: good.sub(/.\z/) { |c| c == "A" ? "B" : "A" },
      wrong_key: forged_token(admin),
      unsigned: JWT.encode({ sub: admin.id.to_s, exp: 1.hour.from_now.to_i }, nil, "none"),
      no_expiry: JWT.encode({ sub: admin.id.to_s }, JwtToken.send(:key), "HS256"),
      expired: forged_token(admin, claims: { exp: 1.minute.ago.to_i }, key: JwtToken.send(:key)),
      deleted_admin: forged_token(admin, claims: { sub: "0" }, key: JwtToken.send(:key))
    }

    tokens.each do |name, token|
      cookies[:admin_token] = token
      get "/admin/news"
      assert_redirected_to "/admin/session/new", name.to_s
    end
  end

  test "state-changing requests need a CSRF token" do
    log_in
    ActionController::Base.allow_forgery_protection = true

    post "/admin/news", params: { news_item: { date: "2026-03-01", title_uk: "Підробка" } }

    assert_response :unprocessable_content
    assert_equal 0, NewsItem.count
  ensure
    ActionController::Base.allow_forgery_protection = false
  end

  test "the backoffice stays Ukrainian for visitors who chose English" do
    get "/?lang=en"
    get "/admin/session/new"

    assert_select "h1", "Вхід"
  end
end
