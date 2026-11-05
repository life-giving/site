require "application_system_test_case"

class PublicSiteSystemTest < ApplicationSystemTestCase
  test "gallery buttons move through the photos and wrap around" do
    item = NewsItem.create!(date: "2026-03-01", title_uk: "Новина", title_en: "News")
    2.times { create_image(item) }

    visit "/news/#{item.id}"
    assert_selector ".slider__count", text: "1 / 2"

    find(".slider__btn--next").click
    assert_selector ".slider__count", text: "2 / 2"
  end

  test "mobile menu opens and closes" do
    page.driver.browser.manage.window.resize_to(390, 800)
    visit "/"

    find(".burger").click
    assert_selector ".header.is-open"

    send_keys :escape
    assert_no_selector ".header.is-open"
  ensure
    page.driver.browser.manage.window.resize_to(1280, 900)
  end
end
