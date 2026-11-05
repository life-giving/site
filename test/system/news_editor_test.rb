require "application_system_test_case"

class NewsEditorTest < ApplicationSystemTestCase
  setup { sign_in }

  test "saving with no Ukrainian title from the English tab shows an error" do
    visit "/admin/news/new"
    click_on "EN"
    fill_in "news_item[title_en]", with: "Only English"
    click_on "Зберегти"

    assert_selector ".admin-alert", text: "Заголовок (UA)"
    assert_field "news_item[title_uk]"
    assert_equal 0, NewsItem.count
  end

  test "tabs swap the language panels" do
    visit "/admin/news/new"
    assert_field "news_item[title_uk]"
    assert_no_field "news_item[title_en]"

    click_on "EN"

    assert_field "news_item[title_en]"
    assert_no_field "news_item[title_uk]"
  end

  test "preview follows the text" do
    visit "/admin/news/new"

    fill_in "news_item[body_uk]", with: "**жирний**"

    assert_selector "#preview_uk strong", text: "жирний"
  end
end
