require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  include ApiTestHelpers

  driven_by :selenium, using: :headless_chrome, screen_size: [ 1280, 900 ]

  setup { Admin::SessionsController::RATE_LIMIT_STORE.clear }

  private

  def sign_in
    admin = create_admin
    visit "/admin/session/new"
    fill_in "email", with: admin.email
    fill_in "password", with: PASSWORD
    click_on "Увійти"
    assert_text "Додати новину"
  end
end
